// ignore_for_file: prefer_final_fields
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
      onDragEnd: (details) {
        player.value = details.offset.dx;
      },
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
  int seconds = 1;

  RxDouble _topDIff = 0.0.obs;
  RxDouble _rightDiff = 150.0.obs;
  RxDouble _bottomDiff = 0.0.obs;
  // lets get the x cordinate value of draggables
  static double player1y = 0;
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
    _topDIff.value = player1y + 3;
    ballOffset = Offset(_rightDiff.value, _topDIff.value);
    // });
  }

  /// this function gets run until the ball doesnt reach one of the bat end !
  void onAnimationEnded(double playeroffset) {
    // check if the ball touched the bat if yes restart the animation
    // get positions
    if (!isGameOver) {
      Offset ballOffset = getballOffset;
      /* print("ball ko position ${ballOffset}");
      print("bat ko position");
      print(_getposition(_player2Key, playeroffset)); */
      if (_isBallOnWall() /* _isBallOnWall(playeroffset) */) {
        // this means it has hitted the fcking wall
        print("wall hit vo");
      } else {
        bouncingPhysics =
            _physics.getAnimationComp(ballOffset, playeroffset, isGoingDown);
        // in micro secs !
        //Timer.periodic(Duration(seconds: 9), (timer) {
        if (ballOffset.dx >= playeroffset) {
          _checkCondition(ballOffset.dx >= playeroffset &&
              ballOffset.dx <= playeroffset + 100);
        } else {
          _checkCondition(ballOffset.dx + 40 >= playeroffset);
        }
      }
    }
  }

  void _checkCondition(bool condition) {
    if (condition) {
      _rightDiff.value = bouncingPhysics.rightBounceTo;

      if (isGoingDown) {
        _topDIff.value = bouncingPhysics.topBounceto;
      } else {
        _topDIff.value = bouncingPhysics.topBounceto;
      }
      isGoingDown = !isGoingDown;
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
    ballOffset =
        Offset(bouncingPhysics.rightBounceTo, bouncingPhysics.topBounceto);
  }

  /* bool _hasHitWall(){
    if(_getposition(key, x)){

    }
  } */
  // so height ko probability ko adar ma right select garam also the second.
  void _onHittingWall() {}

  void _dialogBox() {}

  bool _isBallOnWall() {
    if (ballOffset.dy == player1y + 3 || ballOffset.dy == player2y) {
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

  /// to get the right top
  Physics(this.height, this.width, this.player1y);

  /// get the bounce obj when hit by the surface
  BounceComponenets getAnimationComp(
      Offset ballOffset, double batx1, bool isGoingDown) {
    /// now we will write the p
    // right chai angle ho, 0 huna sakxa yaa, width jati (angle ko lagi main necessity is [point of impact])
    // height ko lagi pani point of impact is important...
    double pointOfImpact = _getPointOfContact(ballOffset);
    double nexttop =  _nextTop(batx1);

    print("nexttop $nexttop");
    double nextRight = _nextRight(nexttop, pointOfImpact, batx1);
    double seconds = 1;
    return BounceComponenets(
      nexttop,
      nextRight,
      1, /* _animatingTime(nexttop) */
    );
  }

  double _getPointOfContact(Offset balloffset) {
    return balloffset.dx + 40 / 2;
  }

// bug chai yo top maxa
  double _nextTop(double batx1,double playerY,double playerX) {
    double diffValue = width*0.32;
    // jati right janxa teti height kaam hudai janxa kyaaa
    if (batx1 > _originOfPlayer) {
      if (batx1 - _originOfPlayer >= diffValue) {
        return playerY - diffValue;
      }
      return ballHeight;
    } else {
      if (_originOfPlayer - batx1 >= diffValue) {
        return playerY - diffValue;
      }
      return ballHeight;
    }
  }

  /// returns width, or 0 if height isnot 0 or max, else returns point of contact
  double _nextRight(double nextTop, double pointOfcontact, double batPosition) {
    // player2y ==20
    if (nextTop == 20 || nextTop == BallControlls.player1y) {
      return pointOfcontact;
    }
    // if height is max the screen
    else {
      if (pointOfcontact >= batPosition / 2) {
        return width;
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
}

/// the components used to bounce the ball
class BounceComponenets {
  /// vertical distance
  double topBounceto;

  /// angle
  double rightBounceTo;

  /// time to animate
  int second;

  BounceComponenets(this.topBounceto, this.rightBounceTo, this.second);
}
