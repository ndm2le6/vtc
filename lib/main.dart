import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MoneyApp());

const navy = Color(0xFF101C3A);
const purple = Color(0xFF6558E8);
const mint = Color(0xFF3DD6B3);
const canvas = Color(0xFFF5F6FB);
final moneyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
final dateFmt = DateFormat('dd/MM/yyyy');

class MoneyApp extends StatelessWidget {
  const MoneyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Tài chính của tôi',
    theme: ThemeData(
      useMaterial3: true, scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: purple, primary: purple),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: navy, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: canvas,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    home: const HomePage(),
  );
}

class Fund {
  String name, note;
  double target, saved;
  DateTime created;
  List<Map<String, dynamic>> history;
  Fund({required this.name, required this.note, required this.target, required this.saved, required this.created, List<Map<String,dynamic>>? history})
    : history = history ?? [];
  Map<String,dynamic> toJson() => {'name':name,'note':note,'target':target,'saved':saved,'created':created.toIso8601String(),'history':history};
  factory Fund.fromJson(Map<String,dynamic> j) => Fund(name:j['name'] ?? 'Quỹ', note:j['note'] ?? '', target:(j['target'] as num).toDouble(), saved:(j['saved'] as num).toDouble(), created:DateTime.tryParse(j['created'] ?? '') ?? DateTime.now(), history:List<Map<String,dynamic>>.from((j['history'] ?? []).map((x)=>Map<String,dynamic>.from(x))));
}

class Wallet {
  String name, type;
  double balance;
  Wallet(this.name,this.type,this.balance);
  Map<String,dynamic> toJson()=>{'name':name,'type':type,'balance':balance};
  factory Wallet.fromJson(Map<String,dynamic> j)=>Wallet(j['name']??'Ví',j['type']??'Tiền mặt',(j['balance'] as num).toDouble());
}

class Debt {
  String name, note;
  double amount, paid;
  DateTime due;
  Debt(this.name,this.note,this.amount,this.paid,this.due);
  Map<String,dynamic> toJson()=>{'name':name,'note':note,'amount':amount,'paid':paid,'due':due.toIso8601String()};
  factory Debt.fromJson(Map<String,dynamic> j)=>Debt(j['name']??'Khoản nợ',j['note']??'',(j['amount'] as num).toDouble(),(j['paid'] as num).toDouble(),DateTime.tryParse(j['due']??'')??DateTime.now());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState()=>_HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loading = true;
  double income = 12500000, expense = 4260000;
  List<Wallet> wallets = [Wallet('Ví chính','Tài khoản',8250000),Wallet('Tiền mặt','Tiền mặt',650000)];
  List<Fund> funds = [];
  List<Debt> debts = [];
  List<Map<String,dynamic>> transactions = [];

  @override void initState(){super.initState(); _load();}
  Future<void> _load() async {
    final p=await SharedPreferences.getInstance();
    try {
      final f=p.getString('funds'); if(f!=null) funds=(jsonDecode(f) as List).map((x)=>Fund.fromJson(x)).toList();
      final w=p.getString('wallets'); if(w!=null) wallets=(jsonDecode(w) as List).map((x)=>Wallet.fromJson(x)).toList();
      final d=p.getString('debts'); if(d!=null) debts=(jsonDecode(d) as List).map((x)=>Debt.fromJson(x)).toList();
      final t=p.getString('transactions'); if(t!=null) transactions=List<Map<String,dynamic>>.from((jsonDecode(t) as List).map((x)=>Map<String,dynamic>.from(x)));
      income=p.getDouble('income')??income; expense=p.getDouble('expense')??expense;
    } catch (_) {}
    if(funds.isEmpty) {
      funds=[Fund(name:'Du lịch Đà Lạt',note:'Đi nghỉ cuối năm cùng gia đình',target:8000000,saved:2450000,created:DateTime.now().subtract(const Duration(days:18)),history:[
        {'title':'Gửi tiền vào quỹ','note':'Bắt đầu quỹ du lịch','amount':1000000,'date':DateTime.now().subtract(const Duration(days:18)).toIso8601String()},
        {'title':'Gửi tiền vào quỹ','note':'Tiết kiệm tuần này','amount':1450000,'date':DateTime.now().subtract(const Duration(days:3)).toIso8601String()},
      ])];
    }
    if(transactions.isEmpty) transactions=[
      {'title':'Lương tháng','category':'Thu nhập','amount':12000000,'date':DateTime.now().subtract(const Duration(days:1)).toIso8601String(),'income':true,'note':'Lương công việc'},
      {'title':'Ăn uống','category':'Ăn uống','amount':185000,'date':DateTime.now().toIso8601String(),'income':false,'note':'Bữa trưa'},
      {'title':'Cà phê','category':'Giải trí','amount':65000,'date':DateTime.now().toIso8601String(),'income':false,'note':'Gặp bạn'},
    ];
    setState(()=>loading=false);
    _save();
  }
  Future<void> _save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('funds',jsonEncode(funds.map((x)=>x.toJson()).toList()));
    await p.setString('wallets',jsonEncode(wallets.map((x)=>x.toJson()).toList()));
    await p.setString('debts',jsonEncode(debts.map((x)=>x.toJson()).toList()));
    await p.setString('transactions',jsonEncode(transactions));
    await p.setDouble('income',income); await p.setDouble('expense',expense);
  }
  double get total => wallets.fold(0,(s,w)=>s+w.balance);
  void _snack(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),behavior:SnackBarBehavior.floating));

  @override Widget build(BuildContext context) {
    if(loading) return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final pages=[_dashboard(),_walletPage(),_fundPage(),_debtPage(),_historyPage()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      floatingActionButton: tab==0 || tab==1 || tab==2 || tab==3 || tab==4 ? FloatingActionButton(
        onPressed:()=>_addForTab(), backgroundColor:purple, foregroundColor:Colors.white,
        child:const Icon(Icons.add_rounded,size:28),
      ):null,
      bottomNavigationBar: NavigationBar(
        selectedIndex:tab, onDestinationSelected:(v)=>setState(()=>tab=v),
        backgroundColor:Colors.white, indicatorColor:purple.withOpacity(.12),
        destinations:const [
          NavigationDestination(icon:Icon(Icons.grid_view_rounded),label:'Tổng quan'),
          NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),label:'Ví'),
          NavigationDestination(icon:Icon(Icons.savings_outlined),label:'Quỹ'),
          NavigationDestination(icon:Icon(Icons.credit_score_outlined),label:'Nợ'),
          NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'Lịch sử'),
        ],
      ),
    );
  }

  Widget _header(String title,{String? subtitle, Widget? trailing})=>Padding(
    padding:const EdgeInsets.fromLTRB(20,18,20,16),
    child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(fontSize:26,fontWeight:FontWeight.w800,color:navy,letterSpacing:-.6)),
      if(subtitle!=null) ...[const SizedBox(height:4),Text(subtitle,style:TextStyle(color:navy.withOpacity(.55),fontSize:13))],
    ])),if(trailing!=null) trailing]),
  );
  Widget _dashboard()=>ListView(padding:EdgeInsets.zero,children:[
    _header('Xin chào 👋',subtitle:'Cùng xem sức khỏe tài chính của bạn',trailing:Container(width:44,height:44,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.notifications_none_rounded,color:navy))),
    Container(margin:const EdgeInsets.symmetric(horizontal:18),padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[navy,Color(0xFF293D72)],begin:Alignment.topLeft,end:Alignment.bottomRight),borderRadius:BorderRadius.circular(28),boxShadow:[BoxShadow(color:navy.withOpacity(.18),blurRadius:22,offset:const Offset(0,10))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(Icons.account_balance_wallet_rounded,color:Colors.white.withOpacity(.7),size:18),const SizedBox(width:8),Text('TỔNG TÀI SẢN',style:TextStyle(color:Colors.white.withOpacity(.72),fontSize:12,fontWeight:FontWeight.w700,letterSpacing:1.1)),const Spacer(),const Icon(Icons.more_horiz,color:Colors.white70)]),
      const SizedBox(height:12),Text(moneyFmt.format(total),style:const TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.w800,letterSpacing:-.7)),
      const SizedBox(height:22),Row(children:[
        Expanded(child:_balancePill(Icons.arrow_downward_rounded,'Thu nhập',moneyFmt.format(income),mint)),
        const SizedBox(width:12),Expanded(child:_balancePill(Icons.arrow_upward_rounded,'Chi tiêu',moneyFmt.format(expense),const Color(0xFFFFA9A9))),
      ]),
    ])),
    Padding(padding:const EdgeInsets.fromLTRB(20,25,20,13),child:Row(children:[const Expanded(child:Text('Tổng quan nhanh',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:navy))),Text('Tháng này',style:TextStyle(color:navy.withOpacity(.5),fontSize:12))])),
    Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Row(children:[
      Expanded(child:_quickTile(Icons.savings_rounded,'Quỹ mục tiêu','${funds.length} quỹ',const Color(0xFFECE9FF),purple,()=>setState(()=>tab=2))),
      const SizedBox(width:10),Expanded(child:_quickTile(Icons.credit_card_rounded,'Khoản nợ','${debts.length} khoản',const Color(0xFFFFEDE5),const Color(0xFFE17B4B),()=>setState(()=>tab=3))),
      const SizedBox(width:10),Expanded(child:_quickTile(Icons.wallet_rounded,'Ví của bạn','${wallets.length} ví',const Color(0xFFE2F8F2),const Color(0xFF149C83),()=>setState(()=>tab=1))),
    ])),
    Padding(padding:const EdgeInsets.fromLTRB(20,26,20,12),child:Row(children:[const Expanded(child:Text('Giao dịch gần đây',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:navy))),TextButton(onPressed:()=>setState(()=>tab=4),child:const Text('Xem tất cả'))])),
    ...transactions.take(4).map(_transactionTile),
    const SizedBox(height:90),
  ]);
  Widget _balancePill(IconData icon,String label,String amount,Color color)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white.withOpacity(.09),borderRadius:BorderRadius.circular(16)),child:Row(children:[Container(width:30,height:30,decoration:BoxDecoration(color:color.withOpacity(.18),borderRadius:BorderRadius.circular(10)),child:Icon(icon,color:color,size:17)),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:TextStyle(color:Colors.white.withOpacity(.65),fontSize:11)),const SizedBox(height:4),Text(amount,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:13))]))]));
  Widget _quickTile(IconData icon,String title,String value,Color bg,Color fg,VoidCallback onTap)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:38,height:38,decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(13)),child:Icon(icon,color:fg)),const SizedBox(height:12),Text(value,style:const TextStyle(color:navy,fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:3),Text(title,style:TextStyle(color:navy.withOpacity(.55),fontSize:11),maxLines:1,overflow:TextOverflow.ellipsis)])));

  Widget _walletPage()=>Column(children:[
    _header('Ví của tôi',subtitle:'Quản lý tiền ở mọi nơi',trailing:IconButton(onPressed:()=>_addWallet(),icon:const Icon(Icons.add_circle,color:purple,size:30))),
    Container(margin:const EdgeInsets.symmetric(horizontal:18),padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:navy,borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('TỔNG SỐ DƯ',style:TextStyle(color:Colors.white.withOpacity(.65),fontSize:12,letterSpacing:1)),const SizedBox(height:8),Text(moneyFmt.format(total),style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w800)),const SizedBox(height:12),Text('${wallets.length} ví đang hoạt động',style:const TextStyle(color:mint,fontSize:12,fontWeight:FontWeight.w600))])),
    const SizedBox(height:12),Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(18,0,18,90),children:wallets.map((w)=>_walletTile(w)).toList())),
  ]);
  Widget _walletTile(Wallet w)=>Container(margin:const EdgeInsets.only(top:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFECE9FF),borderRadius:BorderRadius.circular(15)),child:Icon(w.type.toLowerCase().contains('ngân')?Icons.account_balance:Icons.wallet_rounded,color:purple)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(w.name,style:const TextStyle(color:navy,fontWeight:FontWeight.w800,fontSize:15)),const SizedBox(height:4),Text(w.type,style:TextStyle(color:navy.withOpacity(.5),fontSize:12))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(moneyFmt.format(w.balance),style:const TextStyle(color:navy,fontWeight:FontWeight.w800,fontSize:15)),IconButton(visualDensity:VisualDensity.compact,onPressed:()=>_walletAction(w),icon:const Icon(Icons.more_horiz,color:Colors.grey))])]));

  Widget _fundPage()=>Column(children:[
    _header('Quỹ mục tiêu',subtitle:'Mỗi ngày một chút, gần hơn mục tiêu',trailing:IconButton(onPressed:()=>_addFund(),icon:const Icon(Icons.add_circle,color:purple,size:30))),
    Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(18,0,18,90),children:[
      if(funds.isEmpty) _empty('Chưa có quỹ nào','Tạo quỹ đầu tiên để bắt đầu tiết kiệm',Icons.savings_outlined),
      ...funds.map(_fundCard),
    ])),
  ]);
  Widget _fundCard(Fund f){
    final days=DateTime.now().difference(DateTime(f.created.year,f.created.month,f.created.day)).inDays;
    final progress=f.target<=0?0:(f.saved/f.target).clamp(0.0,1.0);
    return InkWell(onTap:()=>_fundDetails(f),borderRadius:BorderRadius.circular(24),child:Container(margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Container(width:46,height:46,decoration:BoxDecoration(color:const Color(0xFFECE9FF),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.savings_rounded,color:purple,size:24)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(f.name,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:3),Text('Đã lập ${dateFmt.format(f.created)} · $days ngày',style:TextStyle(fontSize:11,color:navy.withOpacity(.52)))])),IconButton(onPressed:()=>_fundDetails(f),icon:const Icon(Icons.chevron_right,color:Colors.grey))]),
      const SizedBox(height:18),Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(moneyFmt.format(f.saved),style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:3),Text('Mục tiêu ${moneyFmt.format(f.target)}',style:TextStyle(color:navy.withOpacity(.5),fontSize:12))])),Text('${(progress*100).round()}%',style:const TextStyle(color:purple,fontWeight:FontWeight.w800,fontSize:15))]),
      const SizedBox(height:10),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:progress,minHeight:8,backgroundColor:const Color(0xFFF0EFF9),color:purple)),
      const SizedBox(height:13),Row(children:[Icon(Icons.history_rounded,size:15,color:navy.withOpacity(.45)),const SizedBox(width:5),Text('${f.history.length} lần ghi nhận',style:TextStyle(color:navy.withOpacity(.55),fontSize:11)),const Spacer(),Text('Thêm tiền  +',style:TextStyle(color:purple,fontSize:12,fontWeight:FontWeight.w800))]),
    ])));
  }
  void _fundDetails(Fund f)=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:canvas,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
    Row(children:[Expanded(child:Text(f.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:navy))),IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close))]),
    Text('Ngày lập quỹ: ${dateFmt.format(f.created)}  ·  ${DateTime.now().difference(DateTime(f.created.year,f.created.month,f.created.day)).inDays} ngày hoạt động',style:TextStyle(color:navy.withOpacity(.6),fontSize:12)),
    const SizedBox(height:8),Text('Mục tiêu ${moneyFmt.format(f.target)} · Đã có ${moneyFmt.format(f.saved)}',style:const TextStyle(fontWeight:FontWeight.w700,color:navy)),
    if(f.note.isNotEmpty) Padding(padding:const EdgeInsets.only(top:8),child:Text('Ghi chú quỹ: ${f.note}',style:TextStyle(color:navy.withOpacity(.7)))),
    const SizedBox(height:18),Row(children:[const Expanded(child:Text('Lịch sử quỹ',style:TextStyle(fontWeight:FontWeight.w800,fontSize:17,color:navy))),TextButton.icon(onPressed:()=>_addToFund(f,ctx),icon:const Icon(Icons.add),label:const Text('Ghi nhận'))]),
    if(f.history.isEmpty) const Padding(padding:EdgeInsets.all(16),child:Text('Chưa có lịch sử giao dịch.')),
    ...f.history.reversed.map((h)=>Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:36,height:36,decoration:BoxDecoration(color:const Color(0xFFE2F8F2),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.south_west,color:Color(0xFF149C83),size:18)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(h['title']??'Giao dịch quỹ',style:const TextStyle(fontWeight:FontWeight.w700,color:navy)),if((h['note']??'').toString().isNotEmpty) Text(h['note'],style:TextStyle(color:navy.withOpacity(.55),fontSize:12)),Text(dateFmt.format(DateTime.tryParse(h['date']??'')??DateTime.now()),style:TextStyle(color:navy.withOpacity(.4),fontSize:11))])),Text('+${moneyFmt.format((h['amount'] as num? ?? 0).toDouble())}',style:const TextStyle(color:Color(0xFF149C83),fontWeight:FontWeight.w800))]))),
    const SizedBox(height:8),SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>_editFund(f,ctx),icon:const Icon(Icons.edit_outlined),label:const Text('Sửa thông tin quỹ'))),
  ]))));
  void _addToFund(Fund f,BuildContext sheetCtx) {
    Navigator.pop(sheetCtx);
    _amountNoteDialog(title:'Ghi nhận vào quỹ',amountLabel:'Số tiền gửi',onSubmit:(amount,note){
      setState((){f.saved+=amount;f.history.add({'title':'Gửi tiền vào quỹ','note':note,'amount':amount,'date':DateTime.now().toIso8601String()});});
      _save();_snack('Đã cập nhật quỹ ${f.name}');
    });
  }
  void _editFund(Fund f,BuildContext sheetCtx){Navigator.pop(sheetCtx);_fundForm(existing:f);}

  Widget _debtPage()=>Column(children:[
    _header('Khoản nợ',subtitle:'Theo dõi khoản phải trả và đã thanh toán',trailing:IconButton(onPressed:()=>_addDebt(),icon:const Icon(Icons.add_circle,color:purple,size:30))),
    Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(18,0,18,90),children:[
      Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:const Color(0xFFFFEDE5),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('TỔNG CÒN PHẢI TRẢ',style:TextStyle(color:navy.withOpacity(.55),fontSize:11,fontWeight:FontWeight.w700,letterSpacing:.8)),const SizedBox(height:8),Text(moneyFmt.format(debts.fold<double>(0,(s,d)=>s+(d.amount-d.paid).clamp(0,d.amount))),style:const TextStyle(color:navy,fontSize:27,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text('${debts.length} khoản đang theo dõi',style:TextStyle(color:navy.withOpacity(.55),fontSize:12))])),
      if(debts.isEmpty) _empty('Chưa có khoản nợ','Thêm khoản vay hoặc khoản cần thanh toán',Icons.credit_score_outlined),
      ...debts.map((d){final remaining=(d.amount-d.paid).clamp(0,d.amount);return Container(margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:Column(children:[Row(children:[Container(width:43,height:43,decoration:BoxDecoration(color:const Color(0xFFFFEDE5),borderRadius:BorderRadius.circular(14)),child:const Icon(Icons.credit_card_rounded,color:Color(0xFFE17B4B))),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(d.name,style:const TextStyle(color:navy,fontWeight:FontWeight.w800)),Text('Hạn: ${dateFmt.format(d.due)}',style:TextStyle(color:navy.withOpacity(.5),fontSize:12))])),Text(moneyFmt.format(remaining),style:const TextStyle(color:navy,fontWeight:FontWeight.w800))]),if(d.note.isNotEmpty) Align(alignment:Alignment.centerLeft,child:Padding(padding:const EdgeInsets.only(top:9),child:Text(d.note,style:TextStyle(color:navy.withOpacity(.55),fontSize:12)))),const SizedBox(height:12),Row(children:[Expanded(child:Text('Đã trả ${moneyFmt.format(d.paid)} / ${moneyFmt.format(d.amount)}',style:TextStyle(color:navy.withOpacity(.55),fontSize:11))),TextButton(onPressed:()=>_payDebt(d),child:const Text('Trả nợ +'))]) ]));}),
    ])),
  ]);

  Widget _historyPage()=>Column(children:[
    _header('Lịch sử giao dịch',subtitle:'Theo dõi các khoản thu chi và ghi chú'),
    Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(18,0,18,90),children:[
      if(transactions.isEmpty) _empty('Chưa có giao dịch','Các khoản thu chi sẽ xuất hiện ở đây',Icons.receipt_long_outlined),
      ...transactions.reversed.map(_transactionTile),
    ])),
  ]);
  Widget _transactionTile(Map<String,dynamic> t)=>Container(margin:const EdgeInsets.only(bottom:9,left:18,right:18),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:(t['income']==true?const Color(0xFFE2F8F2):const Color(0xFFFFEDE5)),borderRadius:BorderRadius.circular(14)),child:Icon(t['income']==true?Icons.south_west_rounded:Icons.north_east_rounded,color:t['income']==true?const Color(0xFF149C83):const Color(0xFFE17B4B))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t['title']??'Giao dịch',style:const TextStyle(color:navy,fontWeight:FontWeight.w800)),const SizedBox(height:3),Text('${t['category']??''} · ${dateFmt.format(DateTime.tryParse(t['date']??'')??DateTime.now())}',style:TextStyle(color:navy.withOpacity(.48),fontSize:11)),if((t['note']??'').toString().isNotEmpty) Text(t['note'],style:TextStyle(color:navy.withOpacity(.55),fontSize:11))])),Text('${t['income']==true?'+':'−'}${moneyFmt.format((t['amount'] as num? ?? 0).toDouble())}',style:TextStyle(color:t['income']==true?const Color(0xFF149C83):navy,fontWeight:FontWeight.w800,fontSize:12))]));

  Widget _empty(String title,String sub,IconData icon)=>Padding(padding:const EdgeInsets.symmetric(vertical:45),child:Column(children:[Icon(icon,size:44,color:purple.withOpacity(.55)),const SizedBox(height:12),Text(title,style:const TextStyle(color:navy,fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(sub,textAlign:TextAlign.center,style:TextStyle(color:navy.withOpacity(.5),fontSize:12))]));
  void _addForTab(){if(tab==0||tab==4)_addTransaction();else if(tab==1)_addWallet();else if(tab==2)_addFund();else _addDebt();}

  Future<void> _addTransaction() async {
    final title=TextEditingController(), amount=TextEditingController(), note=TextEditingController();
    String category='Chi tiêu'; bool isIncome=false; int walletIndex=0;
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,backgroundColor:Colors.white,builder:(ctx)=>StatefulBuilder(builder:(ctx,sm)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+24),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Thêm giao dịch',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:18),
      Row(children:[Expanded(child:ChoiceChip(label:const Text('Chi tiêu'),selected:!isIncome,onSelected:(_)=>sm(()=>isIncome=false))),const SizedBox(width:10),Expanded(child:ChoiceChip(label:const Text('Thu nhập'),selected:isIncome,onSelected:(_)=>sm(()=>isIncome=true)))]),
      const SizedBox(height:12),TextField(controller:title,decoration:const InputDecoration(labelText:'Tên giao dịch',hintText:'Ví dụ: Ăn trưa')),
      const SizedBox(height:10),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Số tiền (VNĐ)')),
      const SizedBox(height:10),DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Danh mục'),items:['Chi tiêu','Ăn uống','Di chuyển','Mua sắm','Hóa đơn','Lương','Thu nhập','Khác'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>sm(()=>category=v??category)),
      const SizedBox(height:10),DropdownButtonFormField<int>(value:walletIndex,decoration:const InputDecoration(labelText:'Ví'),items:wallets.asMap().entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value.name))).toList(),onChanged:(v)=>sm(()=>walletIndex=v??0)),
      const SizedBox(height:10),TextField(controller:note,decoration:const InputDecoration(labelText:'Ghi chú',hintText:'Không bắt buộc')),
      const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Lưu giao dịch'))),
    ]))));
    if(ok==true){final a=double.tryParse(amount.text.replaceAll('.','').replaceAll(',',''))??0;if(title.text.trim().isEmpty||a<=0){_snack('Vui lòng nhập tên và số tiền hợp lệ');return;}
      setState((){final w=wallets[walletIndex];if(isIncome){w.balance+=a;income+=a;}else{w.balance-=a;expense+=a;}transactions.add({'title':title.text.trim(),'category':category,'amount':a,'date':DateTime.now().toIso8601String(),'income':isIncome,'note':note.text.trim(),'wallet':w.name});});_save();_snack('Đã lưu giao dịch');}
  }
  Future<void> _addWallet() async {
    final name=TextEditingController(),amount=TextEditingController(text:'0');String type='Tài khoản';
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,backgroundColor:Colors.white,builder:(ctx)=>StatefulBuilder(builder:(ctx,sm)=>_sheetForm(ctx,'Tạo ví',[
      TextField(controller:name,decoration:const InputDecoration(labelText:'Tên ví',hintText:'Ví dụ: Ví tiết kiệm')),
      const SizedBox(height:10),DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'Loại ví'),items:['Tài khoản','Tiền mặt','Ngân hàng','Ví điện tử','Tiết kiệm'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>sm(()=>type=v??type)),
      const SizedBox(height:10),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Số dư ban đầu')),
    ],()=>Navigator.pop(ctx,true))));
    if(ok==true){final a=double.tryParse(amount.text.replaceAll('.','').replaceAll(',',''))??0;if(name.text.trim().isEmpty){_snack('Nhập tên ví');return;}setState(()=>wallets.add(Wallet(name.text.trim(),type,a)));_save();}
  }
  void _walletAction(Wallet w)=>showModalBottomSheet(context:context,builder:(ctx)=>SafeArea(child:Wrap(children:[
    ListTile(leading:const Icon(Icons.add),title:const Text('Cộng tiền vào ví'),onTap:(){Navigator.pop(ctx);_walletAdjust(w,true);}),
    ListTile(leading:const Icon(Icons.remove),title:const Text('Trừ tiền khỏi ví'),onTap:(){Navigator.pop(ctx);_walletAdjust(w,false);}),
    ListTile(leading:const Icon(Icons.delete_outline,color:Colors.red),title:const Text('Xóa ví'),onTap:(){Navigator.pop(ctx);setState(()=>wallets.remove(w));_save();}),
  ])));
  void _walletAdjust(Wallet w,bool add)=>_amountNoteDialog(title:add?'Cộng tiền vào ví':'Trừ tiền khỏi ví',amountLabel:'Số tiền',onSubmit:(a,n){setState(()=>w.balance+=add?a:-a);_save();_snack('Đã cập nhật số dư');});

  Future<void> _addFund()=>_fundForm();
  Future<void> _fundForm({Fund? existing}) async {
    final name=TextEditingController(text:existing?.name??''),target=TextEditingController(text:existing==null?'':existing.target.toStringAsFixed(0)),saved=TextEditingController(text:existing==null?'0':existing.saved.toStringAsFixed(0)),note=TextEditingController(text:existing?.note??'');
    DateTime created=existing?.created??DateTime.now();
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,backgroundColor:Colors.white,builder:(ctx)=>StatefulBuilder(builder:(ctx,sm)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+22),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(existing==null?'Tạo quỹ mới':'Sửa thông tin quỹ',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:16),
      TextField(controller:name,decoration:const InputDecoration(labelText:'Tên quỹ',hintText:'Ví dụ: Mua laptop')),
      const SizedBox(height:10),TextField(controller:target,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Mục tiêu (VNĐ)')),
      const SizedBox(height:10),TextField(controller:saved,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Số tiền đã có (VNĐ)')),
      const SizedBox(height:10),TextField(controller:note,maxLines:2,decoration:const InputDecoration(labelText:'Ghi chú quỹ',hintText:'Mục đích, kế hoạch, lưu ý...')),
      const SizedBox(height:12),OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:ctx,initialDate:created,firstDate:DateTime(2000),lastDate:DateTime.now());if(d!=null)sm(()=>created=d);},icon:const Icon(Icons.calendar_month),label:Text('Ngày lập quỹ: ${dateFmt.format(created)}')),
      const SizedBox(height:16),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(existing==null?'Tạo quỹ':'Lưu thay đổi'))),
    ]))));
    if(ok==true){final t=double.tryParse(target.text.replaceAll('.','').replaceAll(',',''))??0;final s=double.tryParse(saved.text.replaceAll('.','').replaceAll(',',''))??0;if(name.text.trim().isEmpty||t<=0){_snack('Vui lòng nhập tên quỹ và mục tiêu hợp lệ');return;}
      setState((){if(existing==null){final f=Fund(name:name.text.trim(),note:note.text.trim(),target:t,saved:s,created:created);if(s>0)f.history.add({'title':'Số dư ban đầu','note':'Số tiền khi tạo quỹ','amount':s,'date':created.toIso8601String()});funds.add(f);}else{existing.name=name.text.trim();existing.note=note.text.trim();existing.target=t;existing.saved=s;existing.created=created;}});_save();_snack(existing==null?'Đã tạo quỹ':'Đã cập nhật quỹ');}
  }
  Future<void> _addDebt() async {
    final name=TextEditingController(),amount=TextEditingController(),paid=TextEditingController(text:'0'),note=TextEditingController();DateTime due=DateTime.now().add(const Duration(days:30));
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,backgroundColor:Colors.white,builder:(ctx)=>StatefulBuilder(builder:(ctx,sm)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+22),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Thêm khoản nợ',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:16),
      TextField(controller:name,decoration:const InputDecoration(labelText:'Tên khoản nợ',hintText:'Ví dụ: Vay bạn bè')),
      const SizedBox(height:10),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Tổng khoản nợ')),
      const SizedBox(height:10),TextField(controller:paid,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Đã thanh toán')),
      const SizedBox(height:10),TextField(controller:note,decoration:const InputDecoration(labelText:'Ghi chú')),
      const SizedBox(height:10),OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:ctx,initialDate:due,firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)sm(()=>due=d);},icon:const Icon(Icons.calendar_month),label:Text('Ngày đến hạn: ${dateFmt.format(due)}')),
      const SizedBox(height:16),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Lưu khoản nợ'))),
    ]))));
    if(ok==true){final a=double.tryParse(amount.text.replaceAll('.','').replaceAll(',',''))??0;final p=double.tryParse(paid.text.replaceAll('.','').replaceAll(',',''))??0;if(name.text.trim().isEmpty||a<=0){_snack('Nhập tên và số tiền hợp lệ');return;}setState(()=>debts.add(Debt(name.text.trim(),note.text.trim(),a,p.clamp(0,a).toDouble(),due)));_save();}
  }
  void _payDebt(Debt d)=>_amountNoteDialog(title:'Ghi nhận trả nợ',amountLabel:'Số tiền đã trả',onSubmit:(a,n){setState(()=>d.paid=(d.paid+a).clamp(0,d.amount).toDouble());_save();_snack('Đã cập nhật khoản nợ');});

  void _amountNoteDialog({required String title,required String amountLabel,required void Function(double,String) onSubmit}) {
    final amount=TextEditingController(),note=TextEditingController();
    showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.white,builder:(ctx)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:16),
      TextField(controller:amount,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:amountLabel)),
      const SizedBox(height:10),TextField(controller:note,decoration:const InputDecoration(labelText:'Ghi chú',hintText:'Nội dung giao dịch')),
      const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:(){final a=double.tryParse(amount.text.replaceAll('.','').replaceAll(',',''))??0;if(a<=0){_snack('Nhập số tiền hợp lệ');return;}Navigator.pop(ctx);onSubmit(a,note.text.trim());},child:const Text('Xác nhận'))),
    ])));
  }
  Widget _sheetForm(BuildContext ctx,String title,List<Widget> fields,VoidCallback submit)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+22),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:16),...fields,const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:submit,child:const Text('Lưu')))])));
}
