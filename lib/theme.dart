import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get lampsTheme => ThemeData(
  brightness: Brightness.dark,

  primaryColor: maastrichtBlue,
  primaryColorLight: yankeesBlue,
  primaryColorDark: richBlack,
  primaryColorBrightness: Brightness.dark,

  accentColor: spanishOrange,
  accentColorBrightness: Brightness.light,

  canvasColor: maastrichtBlue,
  backgroundColor: maastrichtBlue,
  buttonColor: lightSeaGreen,
  splashColor: spanishOrange,
  highlightColor: spanishOrange,
  cardColor: yankeesBlue,

  textTheme: TextTheme(
    headline1: GoogleFonts.josefinSans(
        fontWeight: FontWeight.w600,
        fontSize: 96,
        letterSpacing: -1.5,
      color: isabelline
    ),
    button: GoogleFonts.josefinSans(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 1.25
    ),
  )
);

Color get spanishOrange => Color(0xffD96C06);
Color get lightSeaGreen => Color(0xff2292a4);
Color get maastrichtBlue => Color(0xff011627);
Color get yankeesBlue => Color(0xff182b3a);
Color get richBlack => Color(0xff022424);
Color get isabelline => Color(0xffF5EFED);
Color get acidGreen => Color(0xffBDBF09);

Color get goGreen => Color(0xff09BF64);
Color get frenchViolet => Color(0xff8E09BF);
Color get bluePantone => Color(0xff0921BF);