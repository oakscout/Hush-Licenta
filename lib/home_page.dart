import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils.dart';
import 'dart:math' as math;
import 'animation_page.dart';
import 'start_page.dart';

class DataPage extends StatefulWidget {

  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  HealthDataPoint? _latestHeartRate;
  List<HealthDataPoint> healthData = [];
  Map<DateTime, double> _hrvDataMap = {};
  Future<List<BarChartGroupData>>? futureBarGroups;

  get sortedDates => null;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    HealthFactory health = HealthFactory();

    List<HealthDataType> types = [
      HealthDataType.HEART_RATE,
    ];

    /*DateTime startDate = DateTime.now().subtract(Duration(hours: 3));
    DateTime endDate = DateTime.now();*/

    DateTime startDate = DateTime.now().subtract(Duration(days: 10));
    DateTime endDate = DateTime.now().subtract(Duration(days: 3));

    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
      startDate,
      endDate,
      types,
    );

    healthData = HealthFactory.removeDuplicates(healthData);
    _hrvDataMap = calculateHrv(healthData);

    setState(() {
      if (healthData.isNotEmpty) {
        _latestHeartRate = healthData.last;
      }
    });

    if (_hrvDataMap.isNotEmpty) {
      double totalHrv = _hrvDataMap.values.reduce((a, b) => a + b);
      double avgHrv =(totalHrv / _hrvDataMap.length)/1000;
     print(avgHrv);
      checkStressLevelAndShowAlert(context, avgHrv);
      futureBarGroups = getBarChartData();

    }
  }

  Future deconectare() async {
    HealthFactory health = HealthFactory();
    try {
      await health.revokePermissions();
    } catch (error) {
      print("Caught exception in revokeAccess: $error");
    }
  }

  Map<DateTime, double> calculateHrv(List<HealthDataPoint> heartRateData) {
    Map<DateTime, List<double>> rrIntervalsMap = {};

    for (int i = 1; i < heartRateData.length; i++) {
      double rrInterval = heartRateData[i].dateFrom.difference(heartRateData[i - 1].dateFrom).inMilliseconds.toDouble();
      DateTime date = DateTime(heartRateData[i].dateFrom.year, heartRateData[i].dateFrom.month, heartRateData[i].dateFrom.day);

      if (!rrIntervalsMap.containsKey(date)) {
        rrIntervalsMap[date] = [];
      }
      rrIntervalsMap[date]!.add(rrInterval);
    }

    return rrIntervalsMap.map((date, rrIntervals) {
      double average = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
      double variance = rrIntervals.map((interval) => math.pow(interval - average, 2)).reduce((a, b) => a + b) / rrIntervals.length;
      double sdnn = math.sqrt(variance);

      return MapEntry(date, sdnn);
    });
  }
  void checkStressLevelAndShowAlert(BuildContext context, double stressLevel) {
    if (stressLevel > 3000) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: Text('Nivelul de stres este ridicat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.0,
                fontFamily: "Fjord",
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text('Nivelul dvs. de stres a rămas ridicat în ultimele zile. Ar putea fi de ajutor să consultați un specialist.',
              textAlign: TextAlign.center,
              style: TextStyle(
              color: Colors.black,
              fontSize: 16.0,
              fontFamily: "Fjord",
            ),
          ),
            actions: [
              TextButton(
                child: Text('Am înțeles'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<List<BarChartGroupData>> getBarChartData() async {
    if (_hrvDataMap.isEmpty) {
      return [];
    }

    double minHrv = _hrvDataMap.values.reduce(math.min);
    double maxHrv = _hrvDataMap.values.reduce(math.max);

    List<MapEntry<DateTime, double>> sortedEntries = _hrvDataMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // Sort the entries by date

    List<BarChartGroupData> barGroups = sortedEntries.asMap().entries.map((entry) {
      int index = entry.key;
      MapEntry<DateTime, double> mapEntry = entry.value;

      DateTime date = mapEntry.key;
      double hrv = mapEntry.value;

      return BarChartGroupData(
        x: index, // Use the index for the x value
        barRods: [
          BarChartRodData(
            toY: 10 - ((hrv - minHrv) / (maxHrv - minHrv) * 10), // Subtract current value from 10
            color: Colors.white,
          ),
        ],
      );
    }).toList();

    return barGroups;
  }


  @override
  Widget build(BuildContext context) {
    String? savedText = Provider.of<TextProvider>(context).savedText;

    Widget bottomTitles(double value, TitleMeta meta) {
      final titles = <String>[DateTime.now().subtract(Duration(days: 6)).day.toString(),
        DateTime.now().subtract(Duration(days: 5)).day.toString(),
        DateTime.now().subtract(Duration(days: 4)).day.toString(),
        DateTime.now().subtract(Duration(days: 3)).day.toString(),
        DateTime.now().subtract(Duration(days: 2)).day.toString(),
        DateTime.now().subtract(Duration(days: 1)).day.toString(),
        DateTime.now().day.toString()];

      final Widget text = Text(
        titles[value.toInt()],
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFamily: "Fjord",
        ),
      );

      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: text,
      );
    }

    Widget leftTitles(double value, TitleMeta meta) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          value.toInt().toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: "Fjord",
          ),
        ),
      );
    }
    return FutureBuilder<List<BarChartGroupData>>(
        future: futureBarGroups,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData) {
            // return some widget to show while data is still null
            return Center(child: CircularProgressIndicator());
          } else {
            List<BarChartGroupData> barGroups = snapshot.data!;

        return Scaffold(
          backgroundColor: Color(0xFF8EA4CD),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: TextButton(
                      onPressed: () {
                        deconectare();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (
                              context) => const StartPage()),
                        );
                      },
                      child: Text(
                        'Deconectare',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 120,
                  child: Container(
                    padding: EdgeInsets.only(top: 10.0, bottom: 20.0),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 80.0,
                    ),
                  ),
                ),
                Container(
                  height: 360,
                  child: Container(
                    padding: EdgeInsets.only(left: 30.0, right: 30.0),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          "Salut, $savedText",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.0,
                            color: Colors.white,
                            fontFamily: "Fjord",
                          ),
                        ),
                        if (_hrvDataMap.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 30.0,
                                left: 8.0,
                                right: 8.0,
                                bottom: 8.0),
                            child: Container(
                              height: 200,
                              // define the height of the container
                              width: double.infinity,
                              // take the full available width
                              child: BarChart(
                                BarChartData(
                                  maxY: 10,
                                  minY: 0,
                                  barGroups: barGroups,
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: bottomTitles,
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: false,
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: false,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        getTitlesWidget: leftTitles,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: false, // Remove border
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: const Text(
                            "Nivelul de stres din ultima săptămână",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.white,
                              fontFamily: "Fjord",
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(
                              top: 35.0, left: 16.0, right: 16.0),
                          alignment: Alignment.center,
                          child: Text(
                            "Ritm cardiac: ${_latestHeartRate?.value ??
                                '-'} bps",
                            style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.white,
                              fontFamily: "Fjord",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 400, // adjust height as per your requirement
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [

                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AnimationPage(animationType: 'animation1'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            // Button color
                            foregroundColor: Colors.black,
                            // Text color
                            padding: EdgeInsets.all(20.0),
                            // Button padding
                            minimumSize: Size(double.infinity, 80.0),
                            // Button width and height
                            textStyle: TextStyle(fontSize: 20.0),
                            // Text style
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  30.0), // Button border radius
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50.0,
                                height: 50.0,
                                child: Image.asset(
                                  'assets/images/muschi.png',
                                  // Replace with your image asset path
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 8.0),
                              // Space between image and text
                              Expanded(
                                child: Text(
                                  'Relaxare musculară progresivă',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AnimationPage(animationType: 'animation2'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            // Button color
                            onPrimary: Colors.black,
                            // Text color
                            padding: EdgeInsets.all(20.0),
                            // Button padding
                            minimumSize: Size(double.infinity, 80.0),
                            // Button width and height
                            textStyle: TextStyle(fontSize: 20.0),
                            // Text style
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  30.0), // Button border radius
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50.0,
                                height: 50.0,
                                child: Image.asset(
                                  'assets/images/nor.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 8.0),
                              // Space between image and text
                              Expanded(
                                child: Text(
                                  'Imaginație ghidată',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AnimationPage(animationType: 'animation3'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            // Button color
                            onPrimary: Colors.black,
                            // Text color
                            padding: EdgeInsets.all(20.0),
                            // Button padding
                            minimumSize: Size(double.infinity, 80.0),
                            // Button width and height
                            textStyle: TextStyle(fontSize: 20.0),
                            // Text style
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  30.0), // Button border radius
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50.0,
                                height: 50.0,
                                child: Image.asset(
                                  'assets/images/balon.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 8.0),
                              // Space between image and text
                              Expanded(
                                child: Text(
                                  'Respirație ghidată',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    );
  }


}
