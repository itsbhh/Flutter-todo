import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do/utils/todo_list.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
  }

  Future<void> _signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      setState(() {
        _user = userCredential.user;
      });
    } catch (e) {
      print(e);
    }
  }

  void saveNewTask() async {
    if (_controller.text.isNotEmpty && _user != null) {
      await _firestore.collection('users').doc(_user!.uid).collection('tasks').add({
        'task': _controller.text,
        'completed': false,
      });
      _controller.clear();
    }
  }

  void deleteTask(String taskId) async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).collection('tasks').doc(taskId).delete();
    }
  }

  void toggleTaskCompletion(String taskId, bool currentStatus) async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).collection('tasks').doc(taskId).update({
        'completed': !currentStatus,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade300,
      appBar: AppBar(
        title: const Center(
          child: Text(
            'TaskTrek',
            style: TextStyle(fontSize: 30),
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _user == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').doc(_user!.uid).collection('tasks').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return TodoList(
                      taskName: task['task'],
                      taskCompleted: task['completed'],
                      onChanged: (value) => toggleTaskCompletion(task.id, task['completed']),
                      deleteFunction: (context) => deleteTask(task.id),
                    );
                  },
                );
              },
            ),
      floatingActionButton: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: TextField(
                controller: _controller,
                onSubmitted: (value) => saveNewTask(),
                decoration: InputDecoration(
                  hintText: 'Add new Task',
                  filled: true,
                  fillColor: Colors.deepPurple.shade200,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: saveNewTask,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
