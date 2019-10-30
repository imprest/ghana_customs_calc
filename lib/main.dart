import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

final numFormat = new NumberFormat("#,##0.00", "en_US");

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: MaterialApp(
            home: MyTabbedPage(),
            theme: ThemeData(
              primarySwatch: Colors.blue,
            )));
  }
}

class MyTabbedPage extends StatefulWidget {
  const MyTabbedPage({Key key}) : super(key: key);
  @override
  _MyTabbedPageState createState() => _MyTabbedPageState();
}

class _MyTabbedPageState extends State<MyTabbedPage>
    with SingleTickerProviderStateMixin {
  final List<Text> myTitles = <Text>[
    Text('Customs Calculator'),
    Text('Customs Rates')
  ];

  Text _title;
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
    _title = myTitles[0];
    _tabController.addListener(_handleSelected);
  }

  void _handleSelected() {
    setState(() {
      _title = myTitles[_tabController.index];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.account_balance)),
              Row(children: [
                Text('GH₵ ', style: const TextStyle(fontSize: 20)),
                Icon(Icons.swap_horiz),
                Icon(Icons.attach_money)
              ], mainAxisAlignment: MainAxisAlignment.center)
            ],
          ),
          title: Center(child: _title)),
      body: TabBarView(
        controller: _tabController,
        children: [Calculator(), Rates()],
      ),
    );
  }
}

class Rates extends StatefulWidget {
  @override
  RatesState createState() => RatesState();
}

class RatesState extends State<Rates> {
  final _fontSize = TextStyle(fontSize: 18);
  List _rates = [];
  var _refreshed = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    final pref = await SharedPreferences.getInstance();
    _rates = json.decode(pref.getString('rates')??'[]') ?? _rates;
  }

  Future<void> _fetchRates() async {
    final response = await http.get(
        'https://ghanasinglewindow.com/currency-converter/');

    Map<String, dynamic> rates = {'week': ''};

    if (response.statusCode == 200) {
      var document = parse(response.body);
      var ratesElement = document.getElementsByClassName('home-widget-currency')[0].getElementsByTagName('p');
      var week = ratesElement[0].text.trim();

      for (var i = 1; i < ratesElement.length; i = i + 2) {
        rates[ratesElement[i].text] = ratesElement[i+1].text;
      }
      rates['week'] = week;

      if (_rates.length == 0) {
        _rates.insert(0, rates);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('rates', jsonEncode(_rates));
      } else {
        var oldRates = _rates.elementAt(0);
        if (oldRates['week'] == week) {
          return;
        } else {
          _rates.insert(1, oldRates);
          _rates.insert(0, rates);
          _rates.removeRange(2, _rates.length);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('rates', jsonEncode(_rates));
        }
      }
    }
    setState(() { _refreshed = !_refreshed; });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _fetchRates,
        child: ListView(
        cacheExtent: 100,
        padding: const EdgeInsets.all(16.0),
        children: isRatesEmpty()
      )
    );
  }

  List<Widget> isRatesEmpty() {
    if (_rates.length == 0) {
      return [
        Container(
          child: Center(
            child: Text('Pull down to refresh'),
          ))];
    } else {
      return _refreshed ?_buildCards() : _buildCards();
    }
  }
  
  List<Widget> _buildCards() {
    final List<Widget> cards = [];
    for(final x in _rates) {
      cards.add(_buildCard(x));
    }
    return cards;
  }

  Widget _buildRateRow(String currency, String rate) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Expanded(child: Text(currency, style: _fontSize)),
            Expanded(
                child: Text(
              rate,
              style: _fontSize,
              textAlign: TextAlign.right,
            ))
          ],
        ));
  }

  Widget _buildTitle(String week) {
    final _titleSize = const TextStyle(fontSize: 16);

    return Container(
        color: const Color(0xfff5f5f5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text('Week Period:', style: _titleSize)),
            Expanded(
                flex: 3,
                child: Text(
                  week,
                  style: _titleSize,
                  textAlign: TextAlign.right,
                ))
          ],
        ));
  }

  Widget _buildCard(rates) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Column(children: [
      _buildTitle(rates['week']),
      Divider(height: 1),
      _buildRateRow('USD', rates['USD']),
      Divider(),
      _buildRateRow('GBP', rates['GBP']),
      Divider(),
      _buildRateRow('EUR', rates['EUR']),
      Divider(),
      _buildRateRow('JPY', rates['JPY']),
      Divider(),
      _buildRateRow('CAD', rates['CAD']),
      Divider(),
      _buildRateRow('CHF', rates['CHF']),
      Divider(),
      _buildRateRow('AUD', rates['AUD']),
      Divider(),
      _buildRateRow('NZD', rates['NZD']),
      Divider(),
      _buildRateRow('NGN', rates['NGN']),
      Divider(),
      _buildRateRow('DKK', rates['DKK']),
      Divider(),
      _buildRateRow('NOK', rates['NOK']),
      Divider(),
      _buildRateRow('SEK', rates['SEK']),
      Divider(),
      _buildRateRow('XOF', rates['XOF']),
      Divider(),
      _buildRateRow('ZAR', rates['ZAR']),
    ]));
  }
}

class Calculator extends StatefulWidget {
  @override
  CalculatorState createState() => CalculatorState();
}

class CalculatorState extends State<Calculator> {
  final _fontSize = TextStyle(fontSize: 20);
  final _vertical = const EdgeInsets.symmetric(vertical: 16.0);

  Map<String, dynamic> _data = {
    'invoiceFcy': 0.0,
    'invoiceFOBFcy': 0.0,
    'rate': 0.0,
    'invoice': 0.0,
    'invoiceFOB': 0.0,
    'duty': 0.0,
    'dutyValue': 0.0,
    'exciseDuty': 0.0,
    'exciseDutyValue': 0.0,
    'vat': 13.125,
    'vatValue': 0.0,
    'nhil': 2.5,
    'nhilValue': 0.0,
    'getFund': 2.5,
    'getFundValue': 0.0,
    'ccvr': 1.0,
    'ccvrValue': 0.0,
    'prcFee': 1.0,
    'prcFeeValue': 0.0,
    'ecoLevy': 0.5,
    'ecoLevyValue': 0.0,
    'eDevLevy': 0.0,
    'eDevLevyValue': 0.0,
    'exim': 0.75,
    'eximValue': 0.0,
    'gcnet': 0.4,
    'gcnetValue': 0.0,
    'gcnetVat': 13.125,
    'gcnetVatValue': 0.0,
    'gcnetNhil': 2.5,
    'gcnetNhilValue': 0.0,
    'gcnetGetFund': 2.5,
    'gcnetGetFundValue': 0.0,
    'shipper': 9.00,
    'moh': 0.0,
    'mohValue': 0.0,
    'sil': 2.0,
    'silValue': 0.0,
    'auLevy': 0.2,
    'auLevyValue': 0.0,
    'interest': 0.0,
    'total': 0.0
  };

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    final pref = await SharedPreferences.getInstance();
    final data = pref.getString('calculated');
    _data = (data == null) ? _data :  json.decode(data);
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      cacheExtent: 100,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 26.0),
      children: [
        TextField(
          controller:
              TextEditingController(text: _data['invoiceFcy'].toString()),
          onChanged: (text) {
            _data['invoiceFcy'] = double.parse(text);
          },
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          style: _fontSize,
          decoration: InputDecoration(
              labelText: 'Total Invoice in Foreign Currency', hintText: '0.00'),
        ),
        TextField(
          controller:
              TextEditingController(text: _data['invoiceFOBFcy'].toString()),
          onChanged: (text) {
            _data['invoiceFOBFcy'] = double.parse(text);
          },
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          style: _fontSize,
          decoration: InputDecoration(
              labelText: 'Total FOB in Foreign Currency', hintText: '0.00'),
        ),
        TextField(
          controller: TextEditingController(text: _data['rate'].toString()),
          onChanged: (text) => _data['rate'] = double.parse(text),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          style: _fontSize,
          decoration:
              InputDecoration(labelText: 'Rate of Exchange', hintText: '0.00'),
        ),
        Container(
            margin: _vertical,
            child: InkWell(
                child: FlatButton(
                    onPressed: () {
                      _calculate();
                    },
                    color: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.all(18.0),
                    child: Text('Calculate',
                        style: TextStyle(color: Colors.white, fontSize: 20))))),
        Container(
            margin: _vertical,
            child: Row(
              children: <Widget>[
                Expanded(child: Text('Total Invoice', style: _fontSize)),
                Text(
                  numFormat.format(_data['invoice']),
                  style: _fontSize,
                  textAlign: TextAlign.right,
                )
              ],
            )),
        Container(
            margin: _vertical,
            child: Row(
              children: <Widget>[
                Expanded(child: Text('Total FOB', style: _fontSize)),
                Text(
                  numFormat.format(_data['invoiceFOB']),
                  style: _fontSize,
                  textAlign: TextAlign.right,
                )
              ],
            )),
        Divider(),
        _buildRow('DUTY', 'duty', 'dutyValue', '10.00'),
        _buildRow('VAT', 'vat', 'vatValue', '13.125'),
        _buildRow('NHIL', 'nhil', 'nhilValue', '2.50'),
        _buildRow('GET FUND', 'getFund', 'getFundValue', '2.50'),
        _buildRow('EXCISE', 'exciseDuty', 'exciseDutyValue', '0.00'),
        _buildRow('PRC. FEE', 'prcFee', 'prcFeeValue', '1.00'),
        _buildRow('ECO. LEVY', 'ecoLevy', 'ecoLevyValue', '0.50'),
        _buildRow('EDEV. LEVY', 'eDevLevy', 'eDevLevyValue', '0.00'),
        _buildRow('GCNET', 'gcnet', 'gcnetValue', '0.40'),
        _buildRow('GCNET VAT', 'gcnetVat', 'gcnetVatValue', '13.125'),
        _buildRow('GCNET NHIL', 'gcnetNhil', 'gcnetNhilValue', '2.50'),
        _buildRow(
            'GCNET GET FUND', 'gcnetGetFund', 'gcnetGetFundValue', '2.50'),
        _buildRow('SHIPPER', 'shipper', 'shipper', '9.00'),
        _buildRow('MOH GHS', 'moh', 'mohValue', '0.00'),
        _buildRow('SIL', 'sil', 'silValue', '2.00'),
        _buildRow('CCVR', 'ccvr', 'ccvrValue', '1.00'),
        _buildRow('AU. LEVY', 'auLevy', 'auLevyValue', '0.20'),
        _buildRow('INTEREST', 'interest', 'interest', '0.00'),
        Divider(),
        Container(
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text('Total (GH₵):',
                      style: _fontSize, textAlign: TextAlign.right),
                ),
                Expanded(
                    flex: 1,
                    child: Text(numFormat.format(_data['total']),
                        style: _fontSize, textAlign: TextAlign.right))
              ],
            )),
      ],
    );
  }

  void _calculate() async {
    setState(() {
      var rate = _data['rate'];
      var inv = _data['invoice'] = _data['invoiceFcy'] * rate;
      var fob = _data['invoiceFOB'] = _data['invoiceFOBFcy'] * rate;
      var vat = _data['vat'] / 100;
      var nhil = _data['nhil'] / 100;
      var excise = _data['exciseDuty'] / 100;
      var getFund = _data['getFund'] / 100;
      var gcnetVat = _data['gcnetVat'] / 100;
      var gcnetNhil = _data['gcnetNhil'] / 100;
      var gcnetGetFund = _data['gcnetGetFund'] / 100;

      // Calculate Duty, VAT & NHIL on Import Value
      var dutyValue = _data['duty'] / 100 * inv;
      _data['dutyValue'] = dutyValue;
      _data['vatValue'] = vat * inv + vat * dutyValue;
      _data['nhilValue'] = nhil * inv + nhil * dutyValue;
      _data['getFundValue'] = getFund * inv + getFund * dutyValue;
      _data['exciseDutyValue'] = inv * excise;

      // Calculate Inspection, Processing Fee, Ecowas and EXIM Levies
      _data['ccvrValue'] = _data['ccvr'] / 100 * inv;
      _data['prcFeeValue'] = _data['prcFee'] / 100 * inv;
      _data['ecoLevyValue'] = _data['ecoLevy'] / 100 * inv;
      _data['eDevLevyValue'] = _data['eDevLevy'] / 100 * inv;
      _data['eximValue'] = _data['exim'] / 100 * inv;

      // Calculate GCNET Charges, VAT & NHIL
      var gcnetValue = _data['gcnet'] / 100 * fob;
      _data['gcnetValue'] = gcnetValue;
      _data['gcnetVatValue'] = gcnetVat * gcnetValue;
      _data['gcnetNhilValue'] = gcnetNhil * gcnetValue;
      _data['gcnetGetFundValue'] = gcnetGetFund * gcnetValue;

      // Calculate Special Import Levy
      _data['mohValue'] = _data['moh'] / 100 * inv;
      _data['silValue'] = _data['sil'] / 100 * inv;
      _data['auLevyValue'] = _data['auLevy'] / 100 * inv;

      // TOTAL
      _data['total'] = dutyValue +
          _data['vatValue'] +
          _data['nhilValue'] +
          _data['exciseDutyValue'] +
          _data['getFundValue'] +
          _data['ccvrValue'] +
          _data['prcFeeValue'] +
          _data['ecoLevyValue'] +
          _data['eDevLevyValue'] +
          _data['eximValue'] +
          _data['gcnetValue'] +
          _data['gcnetVatValue'] +
          _data['gcnetNhilValue'] +
          _data['gcnetGetFundValue'] +
          _data['mohValue'] +
          _data['silValue'] +
          _data['auLevyValue'] +
          _data['shipper'];

    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calculated', jsonEncode(_data));
  }

  Widget _buildRow(String label, String key, String value, String hint) {
    return Container(
        margin: _vertical,
        child: Row(
          children: <Widget>[
            Expanded(flex: 3, child: Text(label, style: _fontSize)),
            Expanded(
              flex: 1,
              child: TextField(
                controller: TextEditingController(text: _data[key].toString()),
                onChanged: (text) {
                  _data[key] = double.parse(text);
                },
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: _fontSize,
                decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.all(0.0)),
              ),
            ),
            Expanded(
                flex: 2,
                child: Text(numFormat.format(_data[value]),
                    style: _fontSize, textAlign: TextAlign.right))
          ],
        ));
  }
}
