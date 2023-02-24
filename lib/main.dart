import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  // 初期化処理を追加
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyToDoApp());
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // メッセージ表示用
  String infoText = '';
  // 入力したメールアドレス・パスワード
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) => setState(() {
                  email = value;
                }),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'パスワード'),
                onChanged: (String value) => setState(() {
                  password = value;
                }),
              ),
              Container(
                padding: EdgeInsets.all(8),
                // メッセージ表示
                child: Text(infoText),
              ),
              Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text('ユーザー登録'),
                    onPressed: () async {
                      try {
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        await auth.createUserWithEmailAndPassword(
                            email: email, password: password);
                        // ユーザー登録に成功した場合
                        // チャット画面に遷移＋ログイン画面を破棄
                        await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) {
                          return MyToDoApp();
                        }));
                      } catch (e) {
                        // ユーザー登録に失敗した場合
                        setState(() {
                          infoText = "登録に失敗しました：${e.toString()}";
                        });
                      }
                    },
                  ))
            ]),
      )),
    );
  }
}

//タスク一覧ページ
class MyToDoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyToDoApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ToDoListPage(),
    );
  }
}

class ToDoListPage extends StatefulWidget {
  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  @override
  List<String> toDoList = [];
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('タスク一覧画面')),
      body: ListView.builder(
        itemCount: toDoList.length,
        itemBuilder: (context, index) {
          return Card(
              child: ListTile(
            title: Text(toDoList[index]),
          ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newListText = await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) {
            return ToDoAddPage();
          }));
          if (newListText != null) {
            setState(() {
              toDoList.add(newListText);
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

//タスク追加ページ
class ToDoAddPage extends StatefulWidget {
  @override
  _ToDoAddPageState createState() => _ToDoAddPageState();
}

class _ToDoAddPageState extends State<ToDoAddPage> {
  String _text = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('リスト追加画面'),
      ),
      body: Container(
        padding: EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_text, style: TextStyle(color: Colors.blue)),
            TextField(
              onChanged: (String value) {
                setState(() {
                  _text = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_text);
                },
                child: Text(
                  'リスト追加ボタン',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('キャンセル'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
