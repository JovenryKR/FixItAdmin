import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fixit/screens/post_per_day.dart';
import 'package:fixit/utils/colors.dart';
import 'package:fixit/utils/margin.dart';
import 'package:fixit/utils/router.dart';
import 'package:fixit/utils/screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({Key? key}) : super(key: key);

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final FirebaseDatabase db = FirebaseDatabase.instance;
  Iterable<DataSnapshot> posts = [];
  Map<String, dynamic> dailyData = {};
  Map<String, dynamic> weeklyData = {};
  Map<String, dynamic> monthlyData = {};
  Map<String, dynamic> yearlyData = {};
  List days = [];
  List months = [];
  List years = [];
  List categories = [];
  bool showDD = true;
  String weeklySelected = "";
  String monthlySelected = "";

  @override
  void initState() {
    super.initState();
    init();
  }

  readPost() {
    final DatabaseReference postref = db.ref("Posts");
    postref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.children;
      setState(() {
        posts = data;
      });
      getDaily();
      getWeekly();
      getMonthly();
      getYearly();
    });
  }

  init() async {
    Completer complete = Completer();
    final DatabaseReference catref = db.ref("Categories");
    catref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.children;
      List categories = data.map((e) => e.value.toString()).toList();
      setState(() {
        this.categories = categories;
      });
      readPost();
    });
    return complete;
  }

  getDaily() {
    var dateNow = DateTime.parse("2022-04-26"); //DateTime.now();
    var millisecond = dateNow.millisecondsSinceEpoch;
    var limit = dateNow.subtract(const Duration(days: 7));
    var limitmil = limit.millisecondsSinceEpoch;

    List daily = posts.where((element) {
      var date = int.parse(element.child("pTime").value.toString());
      return date >= limitmil;
    }).toList();

    var days = [];
    var data = [];
    Map<String, dynamic> dailyData = {};

    for (var i = 6; i >= 0; i--) {
      var day =
          DateFormat('MMMM d').format(dateNow.subtract(Duration(days: i)));
      days.add(day);
    }

    daily.forEach((element) {
      var date = int.parse(element.child("pTime").value.toString());
      var keydate = DateFormat("MMMM d")
          .format(DateTime.fromMillisecondsSinceEpoch(date));
      if (days.contains(keydate)) {
        data.add(element);
      }
    });

    setState(() {
      this.days = days;
    });

    // data.forEach((element1) {
    //     var date = int.parse(element1.child("pTime").value.toString());
    //     var keydate = DateFormat("MMMM d").format(DateTime.fromMillisecondsSinceEpoch(date));
    //     var type = element1.child("type").value;
    //   });

    days.forEach((element) {
      var categories = {};
      this.categories.forEach((element) {
        categories.addAll({element: []});
      });

      data.forEach((element1) {
        var date = int.parse(element1.child("pTime").value.toString());
        var keydate = DateFormat("MMMM d")
            .format(DateTime.fromMillisecondsSinceEpoch(date));

        if (keydate == element) {
          var type = element1.child("type").value;
          if (this.categories.contains(type)) {
            categories[type].add(element1);
          }
        }
      });

      dailyData.addAll({element: categories});
    });

    dailyData = dailyData.map((key, value) {
      var subvalue = value.map((key, value) {
        return MapEntry(key, value.length);
      });
      return MapEntry(key, subvalue);
    });

    setState(() {
      this.dailyData = dailyData;
    });
  }

  getWeekly() {
    var months = posts
        .map((e) => DateFormat('y-MM').format(
            DateTime.fromMillisecondsSinceEpoch(
                int.parse(e.child("pTime").value.toString()))))
        .toList();
    months = months.toSet().toList();
    setState(() {
      this.months = months;
      weeklySelected = months.first;
    });
    buildWeeklyChart(months.first);
  }

  getMonthly() {
    var years = posts
        .map((e) => DateFormat('y').format(DateTime.fromMillisecondsSinceEpoch(
            int.parse(e.child("pTime").value.toString()))))
        .toList();
    years = years.toSet().toList();
    setState(() {
      this.years = years;
      monthlySelected = years.first;
    });
    builMonthlyAnalytics(years.first);
  }

  getYearly() {
    var data = [];

    Map<String, dynamic> yearlyData = {};

    for (var i = 2; i >= 0; i--) {
      Map<String, dynamic> categoryData = {};
      categories.forEach((element) {
        categoryData.addAll({element: []});
      });

      var datenow = DateTime.now();
      var curyear = datenow.year - i;

      for (var datum in posts) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            int.parse(datum.child("pTime").value.toString()));
        var year = DateFormat("y").format(date);
        var type = datum.child("type").value;
        if (curyear.toString() == year) {
          if (categories.contains(type)) {
            categoryData[type].add(datum);
          }
        }
      }

      yearlyData.addAll({curyear.toString(): categoryData});
    }

    yearlyData = yearlyData.map((key, value) {
      var subvalue = value.map((key1, value1) {
        return MapEntry(key1, value1.length);
      });

      return MapEntry(key, subvalue);
    });

    //print(yearlyData);

    setState(() {
      this.yearlyData = yearlyData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          TextButton(onPressed: (){
            pushRoute(context, url: "/categories");
          }, child: Text("Manage Categories", style: GoogleFonts.poppins(color:Colors.white)))
        ],
        backgroundColor: green,
        leading: IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              cleanPushRoute(context, url: '/login');
            },
            icon: Icon(Icons.logout)),
      ),
      body: SafeArea(
        child: Container(
          width: Screen.width(context),
          height: Screen.height(context),
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              PostPerDayCard(),
              dailyAnalytics(),
              Margin.v(size: 20),
              CupertinoButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text("Print"), Margin.h(), Icon(Icons.print)],
                  ),
                  onPressed: () async {
                    printPDF([dailyAnalytics()]);
                  }),
              Margin.v(size: 50),
              weeklyAnalytics(),
              Margin.v(size: 20),
              CupertinoButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text("Print"), Margin.h(), Icon(Icons.print)],
                  ),
                  onPressed: () async {
                    setState(() {
                      showDD = false;
                    });
                    printPDF([weeklyAnalytics()]);
                  }),
              Margin.v(size: 50),
              monthlyAnalytics(),
              Margin.v(size: 20),
              CupertinoButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text("Print"), Margin.h(), Icon(Icons.print)],
                  ),
                  onPressed: () async {
                    setState(() {
                      showDD = false;
                    });
                    printPDF([
                      monthlyAnalytics(shown: 0),
                      monthlyAnalytics(shown: 1)
                    ]);
                  }),
              Margin.v(size: 50),
              yearlyAnalytics(),
              Margin.v(size: 20),
              CupertinoButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text("Print"), Margin.h(), Icon(Icons.print)],
                  ),
                  onPressed: () async {
                    printPDF([yearlyAnalytics()]);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget dailyAnalytics() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Daily Analytics",
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Margin.v(),
          Wrap(
            direction: Axis.horizontal,
            children: [
              ...categories.map((e) => Container(
                    width: (Screen.width(context) / 2) - 20,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: colors[categories.indexOf(e)],
                        ),
                        Margin.h(),
                        Text(e),
                        Margin.h(size: 20)
                      ],
                    ),
                  ))
            ],
          ),
          Margin.v(size: 50),
          Container(
            width: Screen.width(context),
            height: Screen.height(context) * .5,
            child: LineChart(LineChartData(
                minX: 0,
                maxX: 7,
                minY: 0,
                maxY: 100,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.grey.shade300,
                    getTooltipItems: (items){
                      return items.map((e) {
                        return LineTooltipItem("${e.y}%", GoogleFonts.poppins(fontWeight: FontWeight.w500, color: colors[e.barIndex.toInt()]));
                      }).toList();
                    }
                  )
                ),
                lineBarsData: [
                  ...calculateDailySpots(),
                ],
                titlesData: FlTitlesData(
                    show: true,
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (a, b) {
                              return Text("  ");
                            })),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (a, b) {
                              var key = a.toInt() - 1;
                              if (key < 0) {
                                return Text("");
                              } else {
                                if (days.isNotEmpty && days[key] != null) {
                                  var date = (days[key] as String).split(" ");
                                  var month = date[0].substring(0, 3);
                                  return Text("$month ${date[1]}");
                                } else {
                                  return Text("");
                                }
                              }
                            }))))),
          )
        ],
      ),
    );
  }

  List<LineChartBarData> calculateDailySpots() {
    var values = dailyData.map((key, value) {
      var totalReports = 0;

      value.forEach((key1, value1) {
        totalReports += int.parse(value1.toString());
      });

      var subvalue = value.map((key2, value2) {
        double res = (value2 / totalReports) * 100;
        return MapEntry(
            key2, value2 == 0 ? 0 : double.parse(res.toStringAsFixed(2)));
      });

      return MapEntry(key, subvalue);
    });

    var points = {};

    categories.forEach((element) {
      points.addAll({element: []});
      values.forEach((key, value) {
        value.forEach((a, b) {
          if (a == element) {
            points[element].add(b);
          }
        });
      });
    });

    var coloriter = 0;

    List<LineChartBarData> lines = [];
    points.forEach((key, value) {
      List val = value;
      int iterator = 1;
      lines.add(LineChartBarData(
        color: colors[coloriter],
        spots: [
          FlSpot(0, 0),
          ...val.map((e) => FlSpot((iterator++).toDouble(), e.toDouble()))
        ],
        barWidth: 5,
      ));
      coloriter++;
    });

    return lines;
  }

  weeklyAnalytics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Weekly Analytics",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (months.isNotEmpty && showDD)
              DropdownButton<String>(
                  value: weeklySelected,
                  items: months
                      .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                          child: Text(DateFormat("MMMM y")
                              .format(DateTime.parse(e + "-01"))),
                          value: e))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      weeklySelected = value;
                    });
                    buildWeeklyChart(value);
                  }),
            if (!showDD)
              Text(
                DateFormat("MMMM y")
                    .format(DateTime.parse(weeklySelected + "-01")),
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              )
          ],
        ),
        Wrap(
          direction: Axis.horizontal,
          children: [
            ...categories.map((e) => Container(
                  width: (Screen.width(context) / 2) - 20,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        color: colors[categories.indexOf(e)],
                      ),
                      Margin.h(),
                      Text(e),
                      Margin.h(size: 20)
                    ],
                  ),
                ))
          ],
        ),
        Margin.v(size: 50),
        Container(
          width: Screen.width(context),
          height: Screen.height(context) * .5,
          child: LineChart(LineChartData(
              minX: 0,
              maxX: weeklyData.length.toDouble(),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                ...calculateWeeklySpots(),
              ],
              titlesData: FlTitlesData(
                  show: true,
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (a, b) {
                            return Text("  ");
                          })),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (a, b) {
                            var numbers = [];
                            for (var i = 1; i <= weeklyData.length; i++) {
                              numbers.add(i.toDouble());
                            }
                            if (numbers.contains(a)) {
                              return Text("Week ${a.toInt()}");
                            } else {
                              return Text("");
                            }
                          }))))),
        )
      ],
    );
  }

  buildWeeklyChart(String month) {
    month = month + "-01";
    var firstday = DateTime.parse(month);
    var firstdaymil = firstday.millisecondsSinceEpoch;
    var lastdaymil =
        DateTime(firstday.year, firstday.month + 1, 1).millisecondsSinceEpoch;
    List<DataSnapshot> data = posts.where((element) {
      var date = int.parse(element.child("pTime").value.toString());
      return date >= firstdaymil && date < lastdaymil;
    }).toList();

    int totalDays = int.parse(
        DateFormat("d").format(DateTime(firstday.year, firstday.month, 0)));

    List sundays = [];
    for (var i = 1; i <= totalDays; i++) {
      var date = DateTime(firstday.year, firstday.month, i);
      if (date.weekday == DateTime.sunday) {
        sundays.add(date.millisecondsSinceEpoch);
      }
    }

    Map<String, dynamic> weeklyData = {};

    for (var i = 0; i < sundays.length; i++) {
      Map<String, dynamic> categoryData = {};
      categories.forEach((element) {
        categoryData.addAll({element: []});
      });
      weeklyData.addAll({"week${i + 1}": categoryData});

      if (i > 0) {
        data.forEach((element) {
          var date = int.parse(element.child("pTime").value.toString());
          if (date < sundays[i] && date >= sundays[i - 1]) {
            categories.forEach((cat) {
              if (element.child("type").value == cat) {
                weeklyData["week${i + 1}"][cat].add(element);
              }
            });
          }
        });
      } else {
        data.forEach((element) {
          var date = int.parse(element.child("pTime").value.toString());
          if (date < sundays[i]) {
            categories.forEach((cat) {
              if (element.child("type").value == cat) {
                weeklyData["week${i + 1}"][cat].add(element);
              }
            });
          }
        });
      }
    }

    setState(() {
      this.weeklyData = weeklyData;
    });
  }

  List<LineChartBarData> calculateWeeklySpots() {
    var values = weeklyData.map((key, value) {
      var totalReports = 0;
      var subvalues = value.map((key1, value1) {
        return MapEntry(key1, value1.length);
      });

      subvalues.forEach((key2, value2) {
        totalReports += int.parse(value2.toString());
      });

      subvalues = subvalues.map((key3, value3) {
        double res = (value3 / totalReports) * 100;
        return MapEntry(
            key3, value3 == 0 ? 0 : double.parse(res.toStringAsFixed(2)));
      });

      return MapEntry(key, subvalues);
    });

    var points = {};

    categories.forEach((element) {
      points.addAll({element: []});
      values.forEach((key, value) {
        value.forEach((a, b) {
          if (a == element) {
            points[element].add(b);
          }
        });
      });
    });

    var coloriter = 0;

    List<LineChartBarData> lines = [];
    points.forEach((key, value) {
      List val = value;
      int iterator = 1;
      lines.add(LineChartBarData(
        color: colors[coloriter],
        spots: [
          FlSpot(0, 0),
          ...val.map((e) => FlSpot((iterator++).toDouble(), e.toDouble()))
        ],
        barWidth: 5,
      ));
      coloriter++;
    });

    return lines;
  }

  monthlyAnalytics({int? shown}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Monthly Analytics",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (years.isNotEmpty && showDD)
              // ...months.map((e) => Text(e))
              DropdownButton<String>(
                  value: monthlySelected,
                  items: years
                      .map<DropdownMenuItem<String>>(
                          (e) => DropdownMenuItem(child: Text(e), value: e))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      monthlySelected = value;
                    });
                  }),
            if (!showDD)
              Text(
                monthlySelected,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              )
          ],
        ),
        Wrap(
          direction: Axis.horizontal,
          children: [
            ...categories.map((e) => Container(
                  width: (Screen.width(context) / 2) - 20,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        color: colors[categories.indexOf(e)],
                      ),
                      Margin.h(),
                      Text(e),
                      Margin.h(size: 20)
                    ],
                  ),
                ))
          ],
        ),
        if (shown == null || shown == 0) ...[
          Margin.v(size: 50),
          Text("January - June"),
          Margin.v(size: 20),
          Container(
            width: Screen.width(context),
            height: Screen.height(context) * .5,
            child: LineChart(LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  ...calculateMonthlySpots(0),
                ],
                titlesData: FlTitlesData(
                    show: true,
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (a, b) {
                              return Text("  ");
                            })),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (a, b) {
                              switch (a.toString()) {
                                case "1.0":
                                  return Text("Jan");
                                case "2.0":
                                  return Text("Feb");
                                case "3.0":
                                  return Text("Mar");
                                case "4.0":
                                  return Text("Apr");
                                case "5.0":
                                  return Text("May");
                                case "6.0":
                                  return Text("June");
                                default:
                                  return Text("");
                              }
                            }))))),
          ),
        ],
        if (shown == null || shown == 1) ...[
          Margin.v(size: 50),
          Text("July - December"),
          Margin.v(size: 20),
          Container(
            width: Screen.width(context),
            height: Screen.height(context) * .5,
            child: LineChart(LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  ...calculateMonthlySpots(1),
                ],
                titlesData: FlTitlesData(
                    show: true,
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (a, b) {
                              return Text("  ");
                            })),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (a, b) {
                              switch (a.toString()) {
                                case "1.0":
                                  return Text("July");
                                case "2.0":
                                  return Text("Aug");
                                case "3.0":
                                  return Text("Sep");
                                case "4.0":
                                  return Text("Oct");
                                case "5.0":
                                  return Text("Nov");
                                case "6.0":
                                  return Text("Dec");
                                default:
                                  return Text("");
                              }
                            }))))),
          )
        ]
      ],
    );
  }

  builMonthlyAnalytics(String selectedYear) {
    var data = [];

    posts.forEach((element) {
      var mili = int.parse(element.child("pTime").value.toString());
      var date = DateTime.fromMillisecondsSinceEpoch(mili);
      var year = date.year;
      if (year == int.parse(selectedYear)) {
        data.add(element);
      }
    });

    Map<String, dynamic> monthlyData = {};

    for (var i = 0; i < 12; i++) {
      Map<String, dynamic> categoryData = {};
      categories.forEach((element) {
        categoryData.addAll({element: []});
      });
      var curmonth = DateTime(int.parse(selectedYear), i + 1, 1);
      var curmonthWord = DateFormat("MMMM").format(curmonth);
      var curmonthmili = curmonth.millisecondsSinceEpoch;

      for (var datum in data) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            int.parse(datum.child("pTime").value.toString()));
        var month = DateFormat("MMMM").format(date);
        var type = datum.child("type").value;
        if (curmonthWord == month) {
          if (categories.contains(type)) {
            categoryData[type].add(datum);
          }
        }
      }

      monthlyData.addAll({DateFormat("MMMM").format(curmonth): categoryData});
    }

    monthlyData = monthlyData.map((key, value) {
      var subvalue = value.map((key1, value1) {
        return MapEntry(key1, value1.length);
      });

      return MapEntry(key, subvalue);
    });

    setState(() {
      this.monthlyData = monthlyData;
    });
  }

  List<LineChartBarData> calculateMonthlySpots(int batch) {
    var values = monthlyData.map((key, value) {
      var totalReports = 0;

      value.forEach((key1, value1) {
        totalReports += int.parse(value1.toString());
      });

      var subvalue = value.map((key2, value2) {
        double res = (value2 / totalReports) * 100;
        return MapEntry(
            key2, value2 == 0 ? 0 : double.parse(res.toStringAsFixed(2)));
      });

      return MapEntry(key, subvalue);
    });

    var points = {};

    categories.forEach((element) {
      points.addAll({element: []});
      values.forEach((key, value) {
        var months = [[], []];
        var datenow = DateTime.now();

        for (var i = 1; i <= 6; i++) {
          var month = DateFormat("MMMM").format(DateTime(datenow.year, i, 1));
          months[0].add(month);
        }
        for (var i = 7; i <= 12; i++) {
          var month = DateFormat("MMMM").format(DateTime(datenow.year, i, 1));
          months[1].add(month);
        }

        if (months[batch].contains(key)) {
          value.forEach((a, b) {
            if (a == element) {
              points[element].add(b);
            }
          });
        }
      });
    });

    var coloriter = 0;

    List<LineChartBarData> lines = [];
    points.forEach((key, value) {
      List val = value;
      int iterator = 1;
      lines.add(LineChartBarData(
        color: colors[coloriter],
        spots: [
          FlSpot(0, 0),
          ...val.map((e) => FlSpot((iterator++).toDouble(), e.toDouble()))
        ],
        barWidth: 5,
      ));
      coloriter++;
    });

    return lines;
    // return [];
  }

  yearlyAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Yearly Analytics",
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Margin.v(size: 10),
        Wrap(
          direction: Axis.horizontal,
          children: [
            ...categories.map((e) => Container(
                  width: (Screen.width(context) / 2) - 20,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        color: colors[categories.indexOf(e)],
                      ),
                      Margin.h(),
                      Text(e),
                      Margin.h(size: 20)
                    ],
                  ),
                ))
          ],
        ),
        Margin.v(size: 50),
        Container(
          width: Screen.width(context),
          height: Screen.height(context) * .5,
          child: LineChart(LineChartData(
              minX: 0,
              maxX: 3,
              minY: 0,
              maxY: 100,
              lineBarsData: [
                ...calculateYearlySpots(),
              ],
              titlesData: FlTitlesData(
                  show: true,
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (a, b) {
                            return Text("  ");
                          })),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (a, b) {
                            a = 3 - a;
                            var datenow = DateTime.now();
                            switch (a.toString()) {
                              case "1.0":
                                return Text("${datenow.year - a.toInt()}");
                              case "2.0":
                                return Text("${datenow.year - a.toInt()}");
                              // case "3.0":
                              //   return Text("${datenow.year - a.toInt()}");
                              case "0.0":
                                return Text("${datenow.year - a.toInt()}");
                              default:
                                return Text("");
                            }
                          }))))),
        ),
      ],
    );
  }

  List<LineChartBarData> calculateYearlySpots() {
    var values = yearlyData.map((key, value) {
      var totalReports = 0;

      value.forEach((key1, value1) {
        totalReports += int.parse(value1.toString());
      });

      var subvalue = value.map((key2, value2) {
        double res = (value2 / totalReports) * 100;
        return MapEntry(
            key2, value2 == 0 ? 0 : double.parse(res.toStringAsFixed(2)));
      });

      return MapEntry(key, subvalue);
    });

    var points = {};

    categories.forEach((element) {
      points.addAll({element: []});
      values.forEach((key, value) {
        value.forEach((a, b) {
          if (a == element) {
            points[element].add(b);
          }
        });
      });
    });

    var coloriter = 0;

    List<LineChartBarData> lines = [];
    points.forEach((key, value) {
      List val = value;
      int iterator = 1;
      lines.add(LineChartBarData(
        color: colors[coloriter],
        spots: [
          FlSpot(0, 0),
          ...val.map((e) => FlSpot((iterator++).toDouble(), e.toDouble()))
        ],
        barWidth: 5,
      ));
      coloriter++;
    });

    return lines;
    // return [];
  }

  printPDF(List<Widget> widget) async {
    final sc = ScreenshotController();
    final doc = pw.Document();

    final bytes = await sc.captureFromWidget(
        MediaQuery(data: MediaQueryData(), child: Material(child: widget[0])));

    doc.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(child: pw.Image(pw.MemoryImage(bytes)));
    }));

    if (widget.length > 1) {
      final bytes2 = await sc.captureFromWidget(MediaQuery(
          data: MediaQueryData(), child: Material(child: widget[1])));

      doc.addPage(pw.Page(build: (pw.Context context) {
        return pw.Center(child: pw.Image(pw.MemoryImage(bytes2)));
      }));
    }

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
    setState(() {
      showDD = true;
    });
  }
}
