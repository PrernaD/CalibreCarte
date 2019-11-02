import 'dart:io';

import 'package:calibre_carte/helpers/comments_provider.dart';
import 'package:calibre_carte/helpers/image_cacher.dart';
import 'package:calibre_carte/models/comments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../helpers/books_provider.dart';
import '../models/books.dart';

class BookDetailsScreen extends StatefulWidget {
  static const routeName = '/book-details';
  final int bookId;

  BookDetailsScreen({this.bookId});

  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  Books bookDetails;
  Comments bookComments;
  Future myFuture;
  String localImagePath;

  Future<void> getBookDetails() async {
    bookDetails = await BooksProvider.getBookByID(widget.bookId, null);
    bookComments =
        await CommentsProvider.getCommentByBookID(widget.bookId, null);
    ImageCacher ic = ImageCacher();

    bool exists = await ic.checkIfCachedFileExists(widget.bookId);

    if (!exists){
        await ic.downloadAndCacheImage(bookDetails.path, widget.bookId);
    }

    localImagePath = await ic.returnCachedImagePath(widget.bookId);

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    myFuture = getBookDetails();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: myFuture, // a previously-obtained Future<String> or null
      builder:
          (BuildContext context, AsyncSnapshot<void> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            print("hello");
            return Text('Press button to start.');
          case ConnectionState.active:
            return Text('Something');
          case ConnectionState.waiting:
            return Text('Awaiting result...');
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            return Scaffold(
              appBar: AppBar(
                title: Text(bookDetails.title),
              ),
              body: Container(
                margin: EdgeInsets.all(20),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.file(File(localImagePath)),
                        ),
                      ),
                      DefaultTabController(
                          // The number of tabs / content sections to display.
                          length: 2,
                          child: Column(
                            children: <Widget>[
                              Container(
                                child: TabBar(
                                  unselectedLabelColor: Colors.black,
                                  labelColor: Colors.black,
                                  tabs: [
                                    Tab(
                                      icon: Icon(Icons.directions_car),
                                      text: 'Meta',
                                    ),
                                    Tab(
                                      icon: Icon(Icons.description),
                                      text: 'Description',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 250,
                                child: TabBarView(
                                  children: [
                                    Column(
                                      children: <Widget>[
                                        Text('Title: ${bookDetails.title}'),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                            'Author(s): ${bookDetails.author_sort}'),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text('ISBN: ${bookDetails.isbn}')
                                      ],
                                    ),
                                    SingleChildScrollView(
                                        padding: EdgeInsets.all(10),
                                        child: Container(
                                          child: Html(
                                            data: bookComments.text,
                                          ),
                                        )),
                                  ],
                                ),
                              )
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            );
        }
        return null; // unreachable
      },
    );
  }
}
