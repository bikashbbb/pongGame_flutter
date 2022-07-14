// ignore_for_file: prefer_final_fields
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pong/constans.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pong',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PlayGround(),
    );
  }
}

// yo playground
class PlayGround extends StatefulWidget {
  static ValueNotifier<int> _player1score = ValueNotifier(0);
  static ValueNotifier<int> _player2score = ValueNotifier(0);

  static void increaseScore(bool isOne) {
    if (isOne) {
      _player1score.value++;
    } else {
      _player2score.value++;
    }
  }

  const PlayGround({Key? key}) : super(key: key);

  @override
  State<PlayGround> createState() => _PlayGroundState();
}

class _PlayGroundState extends State<PlayGround> {
  // have this in value notifier !
  double topPadding = 10;
  ValueNotifier<double> _player1X = ValueNotifier(100);
  ValueNotifier<double> _player2X = ValueNotifier(170);

  late BallControlls _ballController;

  @override
  void initState() {
    super.initState();
    // lets animate suruma ball middle ma hunxa after that it will get animated
    _ballController = Get.put(BallControlls(context));

    WidgetsBinding.instance!
        .addPostFrameCallback((_) => _ballController.startBalling());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        toolbarHeight: 10,
        backgroundColor: bgColor,
      ),
      body: Stack(
        // there is a pointer at the left shit haina ani tei pointer chai starting ho k, left is the x cordinate
        children: [
          ValueListenableBuilder(
            valueListenable: _player1X,
            builder: (ctx, value, child) {
              return Positioned(
                  top: 0,
                  left: _player1X.value,
                  child:
                      _drawableButtons(player1color, _player1X, _player1Key));
            },
          ),
          // tykaa ball lai bat le touch garepaxi the isgoing up change hunxa

          Obx(
            () => AnimatedPadding(
                key: _ballGlobalKey,
                curve: Curves.linear,
                onEnd: () {
                  _ballController.onAnimationEnded(_ballController.isGoingDown
                      ? _player2X.value
                      : _player1X.value);
                },
                padding: EdgeInsets.only(
                    top: _ballController._topDIff.value,
                    left: _ballController._rightDiff.value,
                    bottom: _ballController._bottomDiff.value),
                duration: Duration(seconds: _ballController.seconds),
                /* bottom: 639, //,._topDIff.value,
                left: _ballController._rightDiff.value, */
                child: _ball()),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ValueListenableBuilder<int>(
                  valueListenable: PlayGround._player1score,
                  builder: (context, value, child) {
                    return Text(
                      value.toString(),
                      style: const TextStyle(
                          color: Colors.white10,
                          fontSize: 200,
                          fontWeight: FontWeight.bold),
                    );
                  }),
              const Divider(
                height: 1,
                color: Colors.white10,
              ),
              ValueListenableBuilder<int>(
                  valueListenable: PlayGround._player2score,
                  builder: (context, value, child) {
                    return Text(
                      value.toString(),
                      style: const TextStyle(
                          color: Colors.white10,
                          fontSize: 200,
                          fontWeight: FontWeight.bold),
                    );
                  }),
            ],
          ),
          ValueListenableBuilder(
              valueListenable: _player2X,
              builder: (context, v, child) {
                return Positioned(
                    left: _player2X.value,
                    bottom: 10,
                    child:
                        _drawableButtons(player2color, _player2X, _player2Key));
              }),
        ],
      ),
    );
  }

  Widget _drawableButtons(Color color, ValueNotifier player, GlobalKey key) {
    return Draggable(
      key: key,
      ignoringFeedbackSemantics: false,
      rootOverlay: true,
      axis: Axis.horizontal,
      feedback: Container(
        height: 20,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: color,
        ),
      ),
      childWhenDragging: const SizedBox(),
      onDragUpdate: (dragDetails) {
        player.value += dragDetails.delta.dx;
      },
      child: Container(
        height: 20,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: color,
        ),
      ),
    );
  }

  Widget _ball() => CircleAvatar(
        backgroundColor: ballColor,
        child: const SizedBox(
          height: 20,
          width: 20,
        ),
      );
}

GlobalKey _ballGlobalKey = GlobalKey();
GlobalKey _player1Key = GlobalKey();
GlobalKey _player2Key = GlobalKey();

class BallControlls extends GetxController {
  BuildContext context;

  BallControlls(this.context);
  bool isGameOver = false;

  /// use this to difference between is ball boucning on wall or the bat..
  // wall ma bounce vayesi of course top chai 0 or final huna parcha anii ! right chai physics !

  bool isGoingDown = true;
  int seconds = 3;

  RxDouble _topDIff = 0.0.obs;
  RxDouble _rightDiff = 150.0.obs;
  RxDouble _bottomDiff = 0.0.obs;
  // lets get the x cordinate value of draggables
  double player1y = 0;
  double player2y = ballHeight;

  late BounceComponenets bouncingPhysics;
  late Physics _physics;

  late Offset ballOffset;

  void startBalling() {
    // start the animation !
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    double height = mediaQueryData.size.height;
    player1y = height -
        (mediaQueryData.padding.top + bottonHeight + appbarHeight) -
        (ballHeight + 10 + bottonHeight);
    //print("bottom diffvalue $bottomDIffvalue");
    _physics = Physics(height, mediaQueryData.size.width, player1y);
    _topDIff.value = player1y;
    ballOffset = Offset(_rightDiff.value, _topDIff.value);
    // });
  }

  /// this function gets run until the ball doesnt reach one of the bat end !
  void onAnimationEnded(double playeroffset) {
    // check if the ball touched the bat if yes restart the animation
    // get positions
    if (!isGameOver) {
      Offset ballOffset = getballOffset;
      if (_isBallOnWall()) {
        bouncingPhysics = _physics.onHittingWall(isGoingDown, ballOffset);
        _checkCondition(true);
      } else {
        bouncingPhysics =
            _physics.getAnimationComp(ballOffset, playeroffset, isGoingDown);
        if (ballOffset.dx >= playeroffset &&
            ballOffset.dx <= playeroffset + 100) {
          _checkCondition(true);
        } else {
          _checkCondition(ballOffset.dx + 40 >= playeroffset &&
              ballOffset.dx <= playeroffset + 100);
        }
      }
    }
  }

  void _checkCondition(bool condition) {
    if (condition) {
      _rightDiff.value = bouncingPhysics.rightBounceTo;
      _topDIff.value = bouncingPhysics.topBounceto;
    } else {
      // down vaye down nai janxa up vaye up nai janxa.
      if (isGoingDown) {
        _topDIff.value = 2000;
      } else {
        _bottomDiff.value = 2000;
      }
      isGameOver = true;
      PlayGround.increaseScore(isGoingDown);
    }
    if (!_isBallOnWall()) {
      isGoingDown = !isGoingDown;
    }

    ballOffset =
        Offset(bouncingPhysics.rightBounceTo, bouncingPhysics.topBounceto);
  }

  /* bool _hasHitWall(){
    if(_getposition(key, x)){

    }
  } */
  // so height ko probability ko adar ma right select garam also the second.

  void _dialogBox() {}

  bool _isBallOnWall() {
    if (ballOffset.dy == player1y || ballOffset.dy == player2y) {
      return false;
    }
    return true;
  }

  get getballOffset {
    return ballOffset;
  }
}

class Physics {
  double height;
  double width;

  double player1y;

  late double startProbValper = 70;
  late double nexttopprob2;
  late double nextTop;

  /// to get the right top
  Physics(this.height, this.width, this.player1y);

  /// get the bounce obj when hit by the surface
  BounceComponenets getAnimationComp(
      Offset ballOffset, double batx1, bool isGoingDown) {
    /// now we will write the p
    // right chai angle ho, 0 huna sakxa yaa, width jati (angle ko lagi main necessity is [point of impact])
    // height ko lagi pani point of impact is important...
    double pointOfImpact = _getPointOfContact(ballOffset);
    print("ball ko offse$ballOffset");
    nexttopprob2 = _nextTopProb2(batx1, isGoingDown);
    double nexttopVal = _nextTop();
    nextTop = nexttopVal;
    double nextRight = _nextRight(nexttopVal, pointOfImpact, batx1);
    double seconds = 1;
    return BounceComponenets(
        nextTop,
        nextRight,
        1,
        /* _animatingTime(nexttop) */
        false);
  }

  double _getPointOfContact(Offset balloffset) {
    return (balloffset.dx + 40) / 2;
  }

  /// returns the top of the ball with using probability/random
  double _nextTop() {
    if (nexttopprob2 == 20 || nexttopprob2 == player1y) {
      return nexttopprob2;
    }
    Random random = Random();
    return _startProbVal() +
        random.nextInt(nexttopprob2.round() - _startProbVal()).toDouble();
  }

// bug chai yo top maxa
  double _nextTopProb2(double batx1, bool isGoingDown) {
    double diff = batx1 - _originOfPlayer;
    print("batx1 $batx1 origin $_originOfPlayer");
    print(_getDiffPer(diff.abs()));
    if (_getDiffPer(diff.abs()) >= 20) {
      // return height with cal
      double widthPerc = (batx1 / width) * 100;
      if (!isGoingDown) {
        return height - (widthPerc * height) / 100;
      }
      return (widthPerc * height) / 100;
    }
    // ava lets use the isGoingDown shit !!
    // return down playerY or upplayerY on context;
    if (isGoingDown) {
      return 20;
    }
    return player1y;
  }

  /// returns width, or 0 if height isnot 0 or max, else returns point of contact
  double _nextRight(double nextTop, double pointOfcontact, double batPosition) {
    // player2y ==20

    Random random = Random();
    if (nextTop == 20 || nextTop == player1y) {
      print("point of c$pointOfcontact, bat po$batPosition");
      if (pointOfcontact >= (batPosition + 100) / 2) {
        /// debug this !
        int range = (width - pointOfcontact.toInt()).toInt();
        return pointOfcontact + random.nextInt(range).toDouble();
      }
      return pointOfcontact - random.nextInt(pointOfcontact.toInt());
    }
    // if height is max the screen
    else {
      if (pointOfcontact >= (batPosition+100) / 2) {
        return width - 40;
      }
      return 0;
    }
  }

  // time depends on the nextheight top
  /* int _animatingTime(double nextTop) {
    return nextTop;
  } */

  get _originOfPlayer {
    return width / 2;
  }

  /// calculates time to travel with the use of next top over height out of 2 seconds
  int _getSeconds() {
    return 1;
  }

  int _startProbVal() {
    return ((nexttopprob2 * startProbValper) / 100).round();
  }

  double _getDiffPer(double diff) {
    return (diff * 100) / width;
  }

  BounceComponenets onHittingWall(bool isGoingDown, Offset ballPosition) {
    // dowb ho vane 20, natra chai player y ]
    int rightVal = Random().nextInt(width.toInt() - 40);
    // we will use the height ani tesko adarma random function chalayera halka criteria rakhne
    if (!isGoingDown) {
      nextTop = 20;
    } else {
      nextTop = player1y;
    }
    return BounceComponenets(nextTop, rightVal.toDouble(), 2, true);
  }
}

/// the components used to bounce the ball
class BounceComponenets {
  /// vertical distance
  double topBounceto;

  /// angle
  double rightBounceTo;

  /// time to animate
  int second;

  /// is the ball on the wall
  bool isOnWall;
  BounceComponenets(
      this.topBounceto, this.rightBounceTo, this.second, this.isOnWall);
}
