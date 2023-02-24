import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';

void main() async {
  // 初期化処理を追加
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyToDoApp());
}

//ログインページ
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
                        final result =
                            await auth.createUserWithEmailAndPassword(
                                email: email, password: password);
                        // ユーザー登録に成功した場合
                        // チャット画面に遷移＋ログイン画面を破棄
                        await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) {
                          return ToDoListPage(result.user!);
                        }));
                      } catch (e) {
                        // ユーザー登録に失敗した場合
                        setState(() {
                          infoText = "登録に失敗しました：${e.toString()}";
                        });
                      }
                    },
                  )),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: OutlinedButton(
                  child: Text('ログイン'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでログイン
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.signInWithEmailAndPassword(
                          email: email, password: password);
                      // ログインに成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) {
                        return ToDoListPage(result.user!);
                      }));
                    } catch (e) {
                      // ログインに失敗した場合
                      setState(() {
                        infoText = "ログインに失敗しました：${e.toString()}";
                      });
                    }
                  },
                ),
              )
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
      debugShowCheckedModeBanner: false, // 追加
      title: 'MyToDoApp',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
      ), // ログイン画面を表示
      home: LoginPage(),
    );
  }
}

class ToDoListPage extends StatefulWidget {
  ToDoListPage(this.user);
  // ユーザー情報
  final User user;
  @override
  _ToDoListPageState createState() => _ToDoListPageState(user);
}

class _ToDoListPageState extends State<ToDoListPage> {
  _ToDoListPageState(this.user);
  final User user;
  @override
  List<String> toDoList = [];
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('タスク一覧画面'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // ログアウト処理
              // 内部で保持しているログイン情報等が初期化される
              // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫です）
              await FirebaseAuth.instance.signOut();
              // ログイン画面に遷移＋チャット画面を破棄
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            // 投稿メッセージ一覧を取得（非同期処理）
            // 投稿日時でソート
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              // データが取得できた場合
              if (snapshot.hasData) {
                final List<DocumentSnapshot> documents = snapshot.data!.docs;
                return ListView(
                  children: documents.map((document) {
                    return Card(
                        child: ListTile(
                      title: Text(document['text']),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd')
                            .format(document['deadLine'].toDate()),
                      ),
                      trailing: Text(
                          '優先度' + document['level'].toStringAsPrecision(1)),
                      onTap: () async {
                        await Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) {
                          return TaskContents(user, document['text']);
                        }));
                      },
                    ));
                  }).toList(),
                );
              }
              // データが読込中の場合
              return Center(
                child: Text('読込中...'),
              );
            },
          ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newListText = await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) {
            return ToDoAddPage(user);
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
  ToDoAddPage(this.user);
  final User user;
  @override
  _ToDoAddPageState createState() => _ToDoAddPageState();
}

class _ToDoAddPageState extends State<ToDoAddPage> {
  String _text = '';
  String _description = '';
  DateTime _deadLine = DateTime.now();
  double _level = 1;

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
              decoration: InputDecoration(labelText: 'タイトル'),
              onChanged: (String value) {
                setState(() {
                  _text = value;
                });
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '詳細'),
              // 複数行のテキスト入力
              keyboardType: TextInputType.multiline,
              // 最大3行
              maxLines: 3,
              onChanged: (String value) {
                setState(() {
                  _description = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: Text('期限',
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Colors.grey)),
            ),
            Text(DateFormat('yyyy-MM-dd').format(_deadLine),
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )),
            OutlinedButton(
                onPressed: () {
                  DatePicker.showDatePicker(context,
                      showTitleActions: true,
                      minTime: DateTime(2000, 1, 1),
                      maxTime: DateTime(2050, 1, 1),
                      onConfirm: (DateTime date) {
                    setState(() {
                      _deadLine = date;
                    });
                  }, currentTime: DateTime.now(), locale: LocaleType.jp);
                },
                child: const Text(
                  '期限を選択',
                  style: TextStyle(color: Colors.blue),
                )),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: Text('優先度',
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Colors.grey)),
            ),
            Slider(
                value: _level,
                min: 1,
                max: 5,
                label: _level.round().toString(),
                divisions: 5,
                inactiveColor: Colors.black12,
                activeColor: Colors.red,
                onChanged: (level) {
                  setState(() {
                    _level = level.round().toDouble();
                  });
                }),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                child: Text(
                  'リスト追加ボタン',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  final date =
                      DateTime.now().toLocal().toIso8601String(); // 現在の日時
                  final email = widget.user.email; // AddPostPage のデータを参照
                  // 投稿メッセージ用ドキュメント作成
                  await FirebaseFirestore.instance
                      .collection('posts') // コレクションID指定
                      .doc() // ドキュメントID自動生成
                      .set({
                    'text': _text,
                    'description': _description,
                    'deadLine': _deadLine,
                    'level': _level,
                    'email': email,
                    'date': date
                  });
                  Navigator.of(context).pop(_text);
                },
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

//タスク詳細ページ
class TaskContents extends StatefulWidget {
  TaskContents(this.user, this.text);
  final User user;
  final String text;
  @override
  _TaskContentsPageState createState() => _TaskContentsPageState(text);
}

class _TaskContentsPageState extends State<TaskContents> {
  _TaskContentsPageState(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('タスク詳細画面'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // ログアウト処理
              // 内部で保持しているログイン情報等が初期化される
              // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫です）
              await FirebaseAuth.instance.signOut();
              // ログイン画面に遷移＋チャット画面を破棄
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            // 投稿メッセージ一覧を取得（非同期処理）
            // 投稿日時でソート
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('text', isEqualTo: text)
                .snapshots(),
            builder: (context, snapshot) {
              // データが取得できた場合
              if (snapshot.hasData) {
                final List<DocumentSnapshot> documents = snapshot.data!.docs;
                return ListView(
                  children: documents.map((document) {
                    return Card(
                        child: ListTile(
                      title: Text(document['text']),
                      subtitle: Text(document['description']),
                    ));
                  }).toList(),
                );
              }
              // データが読込中の場合
              return Center(
                child: Text('読込中...'),
              );
            },
          ))
        ],
      ),
    );
  }
}
