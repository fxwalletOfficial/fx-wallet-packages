import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:k_chart_flutter/chart_translations.dart';
import 'package:k_chart_flutter/k_chart_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const MyHomePage(title: 'Flutter Demo Home Page')
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  List<KLineEntity>? data;
  bool showLoading = true;
  MainState _mainState = MainState.MA;
  bool _volHidden = false;
  SecondaryState _secondaryState = SecondaryState.MACD;
  bool isLine = true;
  bool isChinese = true;
  bool _hideGrid = false;
  bool _showNowPrice = true;
  List<DepthEntity>? _bids, _asks;
  bool isChangeUI = false;
  bool _isTrendLine = false;

  ChartStyle chartStyle = ChartStyle(
    select: const ChartSelectStyle(y: ChartCrossLineStyle(color: Colors.red, length: 20))
  );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    getData('1day');

    final result = await rootBundle.loadString('assets/depth.json');

    final parseJson = json.decode(result);
    final tick = parseJson['tick'] as Map<String, dynamic>;

    final List<DepthEntity> bids = (tick['bids'] as List<dynamic>).map((item) => DepthEntity(item[0] as double, item[1] as double)).toList();
    final List<DepthEntity> asks = (tick['asks'] as List<dynamic>).map((item) => DepthEntity(item[0] as double, item[1] as double)).toList();

    initDepth(bids, asks);
  }

  void initDepth(List<DepthEntity>? bids, List<DepthEntity>? asks) {
    if (bids == null || asks == null || bids.isEmpty || asks.isEmpty) return;

    _bids = [];
    _asks = [];
    double amount = 0.0;
    bids.sort((left, right) => left.price.compareTo(right.price));
    //累加买入委托量
    for (var item in bids.reversed) {
      amount += item.vol;
      item.vol = amount;
      _bids!.insert(0, item);
    }

    amount = 0.0;
    asks.sort((left, right) => left.price.compareTo(right.price));
    //累加卖出委托量
    for (var item in asks) {
      amount += item.vol;
      item.vol = amount;
      _asks!.add(item);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Stack(children: [
          SizedBox(
            height: 450,
            width: double.infinity,
            child: KChartWidget(
              data: data,
              style: chartStyle,
              isLine: isLine,
              isTrendLine: _isTrendLine,
              mainState: _mainState,
              volHidden: _volHidden,
              secondaryState: _secondaryState,
              timeFormat: TimeFormat.YEAR_MONTH_DAY,
              translations: kChartTranslations,
              showNowPrice: _showNowPrice,
              hideGrid: _hideGrid,
              isTapShowInfoDialog: true,
              maDayList: const [1, 100, 1000],
              dataFormat: (value) => value.toStringAsFixed(2),
            )
          ),
          if (showLoading) Container(
            width: double.infinity,
            height: 450,
            alignment: Alignment.center,
            child: const CircularProgressIndicator()
          )
        ]),
        buildButtons(),
        if (_bids != null && _asks != null) SizedBox(
          height: 230,
          width: double.infinity,
          child: DepthChart(bids: _bids!, asks: _asks!, colors: const DepthColors())
        )
      ]
    );
  }

  Widget buildButtons() {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      children: <Widget>[
        button("Time Mode", onPressed: () => isLine = true),
        button("K Line Mode", onPressed: () => isLine = false),
        button("TrendLine", onPressed: () => _isTrendLine = !_isTrendLine),
        button("Line:MA", onPressed: () => _mainState = MainState.MA),
        button("Line:BOLL", onPressed: () => _mainState = MainState.BOLL),
        button("Hide Line", onPressed: () => _mainState = MainState.NONE),
        button("Secondary Chart:MACD", onPressed: () => _secondaryState = SecondaryState.MACD),
        button("Secondary Chart:KDJ", onPressed: () => _secondaryState = SecondaryState.KDJ),
        button("Secondary Chart:RSI", onPressed: () => _secondaryState = SecondaryState.RSI),
        button("Secondary Chart:WR", onPressed: () => _secondaryState = SecondaryState.WR),
        button("Secondary Chart:CCI", onPressed: () => _secondaryState = SecondaryState.CCI),
        button("Secondary Chart:Hide", onPressed: () => _secondaryState = SecondaryState.NONE),
        button(_volHidden ? "Show Vol" : "Hide Vol", onPressed: () => _volHidden = !_volHidden),
        button("Change Language", onPressed: () => isChinese = !isChinese),
        button(_hideGrid ? "Show Grid" : "Hide Grid", onPressed: () => _hideGrid = !_hideGrid),
        button(_showNowPrice ? "Hide Now Price" : "Show Now Price", onPressed: () => _showNowPrice = !_showNowPrice),
      ]
    );
  }

  Widget button(String text, {VoidCallback? onPressed}) {
    return TextButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed();
          setState(() {});
        }
      },
      style: TextButton.styleFrom(
        minimumSize: const Size(88, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        ),
        backgroundColor: Colors.blue
      ),
      child: Text(text)
    );
  }

  void getData(String period) {
    /*
     * 可以翻墙使用方法1加载数据，不可以翻墙使用方法2加载数据，默认使用方法1加载最新数据
     */
    // final Future<String> future = getChatDataFromInternet(period);
    final Future<String> future = getChatDataFromJson();
    future.then((String result) {
      solveChatData(result);
    }).catchError((_) {
      showLoading = false;
      setState(() {});
    });
  }

  //获取火币数据，需要翻墙
  Future<String> getChatDataFromInternet(String? period) async {
    var url = 'https://api.huobi.br.com/market/history/kline?period=${period ?? '1day'}&size=300&symbol=btcusdt';
    late String result;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      result = response.body;
    } else {
      debugPrint('Failed getting IP address');
    }
    return result;
  }

  // 如果你不能翻墙，可以使用这个方法加载数据
  Future<String> getChatDataFromJson() async {
    return rootBundle.loadString('assets/chatData.json');
  }

  void solveChatData(String result) {
    final Map parseJson = json.decode(result) as Map<dynamic, dynamic>;
    final list = parseJson['data'] as List<dynamic>;
    data = list.map((item) => KLineEntity.fromJson(item as Map<String, dynamic>))
      .toList()
      .reversed
      .toList()
      .cast<KLineEntity>();

    DataUtil.calculate(data!);
    showLoading = false;
    setState(() {});
  }
}
