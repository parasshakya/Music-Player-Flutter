import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final assetsAudioPlayer = AssetsAudioPlayer();
  List<DocumentSnapshot>? _list;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('songs')
          .orderBy('song_name')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else {
          _list = snapshot.data!.docs;

          return ListView.custom(
            padding: EdgeInsets.only(top: 8.0,bottom: 10.0),
              childrenDelegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {

                  return buildList(context, _list![index]);

                },
                childCount: _list!.length,
              ));
        }
      },
    );
  }
  String getTimeString(int seconds) {
    String minuteString =
        '${(seconds / 60).floor() < 10 ? 0 : ''}${(seconds / 60).floor()}';
    String secondString = '${seconds % 60 < 10 ? 0 : ''}${seconds % 60}';
    return '$minuteString:$secondString'; // Returns a string with the format mm:ss
  }

  Widget buildList(BuildContext context, DocumentSnapshot documentSnapshot) {
    // DateFormat time = DateFormat.ms();
    final player = AssetsAudioPlayer.withId('${documentSnapshot.id}');
    Map<String, dynamic> data = documentSnapshot.data() as Map<String,dynamic>;
    player.open(
      Audio.network(data['song_url']),autoStart: false,   );
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0)
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['song_name'],
                    style: TextStyle(fontSize: 20.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Divider(),
                  Text(
                    data['artist_name'],
                    style: Theme.of(context).textTheme.caption!.copyWith(fontSize: 10.0),
                  ),
                  Divider(),
                    player.builderRealtimePlayingInfos(builder: (context,realTimePlayingInfo){
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                             getTimeString(realTimePlayingInfo.currentPosition.inSeconds)
                          ),
                          Slider(
                            value: realTimePlayingInfo.currentPosition.inSeconds.toDouble(),
                            max: realTimePlayingInfo.duration.inSeconds.toDouble(),
                            min: 0,
                            onChanged: (value) async {
                             await player.seek(Duration(seconds: value.toInt()));
                            },
                            activeColor: Colors.red,
                            inactiveColor: Colors.black26,
                          ),
                          // Flexible(
                          //   child: Text(
                          //      ' ${realTimePlayingInfo.duration.inMinutes}:${realTimePlayingInfo.duration.inSeconds}',
                          //   overflow: TextOverflow.ellipsis,
                          //   maxLines: 3,),
                          // ),
                        ],
                      );

                    }),
                  // PlayerBuilder.currentPosition(
                  //     player: player,
                  //     builder: (context, duration) {
                  //       return Slider(
                  //         max: 50,
                  //         min: 0,
                  //         onChanged: (value) async{
                  //           setState(() {
                  //             _value = value;
                  //           });
                  //           await player.seek(Duration(minutes: value.toInt()));
                  //         },
                  //         value: _value,
                  //
                  //       );
                  //     }
                  // )

                ],
              ),
            ),
            Expanded(
              child: IconButton(
                icon: StreamBuilder<bool>(
                  initialData: false,
                  stream: player.isPlaying,
                  builder: (context, snapshot) {
                    final bool isPlaying = snapshot.data!;
                    return Icon( isPlaying ? Icons.pause : Icons.play_arrow);
                  }
                ),
                onPressed: () async {
                  await player.playOrPause();
                }),
            ),

            Expanded(
              child: IconButton(
                icon: Icon(Icons.stop),
                onPressed: () async{
                  await player.stop();
                },
              ),
            ),
          ],
        ),
      ),
      elevation: 10.0,
    );
  }
}