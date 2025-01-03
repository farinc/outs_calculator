import 'dart:math';

typedef Packing = ({double fill, int outs, Layout layout});

typedef Layout = ({
  List<ItemRectangle> rects,
  double largeWidth,
  double largeHeight,
  double smallWidth,
  double smallHeight
});

class ItemRectangle extends Rectangle {
  final bool isFlipped;

  ItemRectangle(
      super.left, super.top, super.width, super.height, this.isFlipped);
}

Packing getBestPack(double largeWidth, double largeHeight, double smallWidth,
    double smallHeight) {
  Packing pack1 = _pack(largeWidth, largeHeight, smallWidth, smallHeight);
  Packing pack2 = _pack(largeWidth, largeHeight, smallHeight, smallWidth);

  if (pack1.outs > pack2.outs) {
    return pack1;
  } else {
    return pack2;
  }
}

Packing _pack(double largeWidth, double largeHeight, double smallWidth,
    double smallHeight) {
  var spaces = <MutableRectangle>[];
  var layout = <ItemRectangle>[];

  // Determine if there is enough space for a rotated small rectangle to fit. At
  // this point, we only compare the first sides (S1's) as we flip them in
  // getBestPack
  if (largeHeight % smallHeight >= smallWidth) {
    //            S2
    //     _______________
    //     |             |
    //  S1 |             |
    //     | main space  |
    //     |             |
    //     |_____________|_
    //     |  horizonal  |  at least >= smallWidth
    //     |_____________|__
    // Add horizonal space above the main space
    var wholeHeight = largeHeight - (largeHeight % smallHeight);
    spaces.add(MutableRectangle(
        0, wholeHeight, largeWidth, largeHeight % smallHeight));
    spaces.add(MutableRectangle(0, 0, largeWidth, wholeHeight)); // main space
  } else if (largeWidth % smallWidth >= smallHeight) {
    var wholeWidth = largeWidth - (largeWidth % smallWidth);
    spaces.add(
        MutableRectangle(wholeWidth, 0, largeWidth % smallWidth, largeHeight));
    spaces.add(MutableRectangle(0, 0, wholeWidth, largeHeight)); // main space
  } else {
    spaces.add(MutableRectangle(0, 0, largeWidth, largeHeight));
  }

  var hasSpace = false;

  do {
    hasSpace = false;

    for (int i = spaces.length - 1; i >= 0; i--) {
      var space = spaces[i];

      double width;
      double height;
      bool isFlipped;
      if (space.width >= smallWidth && space.height >= smallHeight) {
        isFlipped = false;
      } else if (space.width >= smallHeight && space.height >= smallWidth) {
        isFlipped = true;
      } else {
        continue;
      }

      hasSpace = true;

      if (isFlipped) {
        width = smallHeight;
        height = smallWidth;
      } else {
        width = smallWidth;
        height = smallHeight;
      }

      layout
          .add(ItemRectangle(space.left, space.top, width, height, isFlipped));

      if (space.width == width) {
        //            S2
        //     _______________
        //     |     box     |
        //  S1 |_____________|
        //     |             |
        //     |  remaining  |
        //     |_____________|_
        //     |  horizonal  |  at least >= smallS2 (not always here)
        //     |_____________|__
        // Our box fits the width of the remaining space.
        space.height -= height;
        space.top += height;
      } else if (space.height == height) {
        //            S2
        //     _______________
        //     | b |         |
        //  S1 | o |         |
        //     | x |remainng |
        //     |   |         |
        //     |___|_________|__
        //     |  horizonal  |  at least >= smallS2 (not always here)
        //     |_____________|__
        // Our box fits the height of the remaining space.
        space.width -= width;
        space.left += width;
      } else {
        //            S2
        //     _______________
        //     |       |     |
        //  S1 |  box  | new |
        //     |_______|_____|
        //     |  remaining  |
        //     |_____________|__
        //     |  horizonal  |  at least >= smallS2 (not always here)
        //     |_____________|__
        // Neither fits exactly the height or width

        spaces.add(MutableRectangle(
            space.left + width, space.top, space.width - width, height));
        space.top += height;
        space.height -= height;
      }
      break;
    }
  } while (hasSpace);

  var outs = layout.length;
  var maxOuts = (largeWidth * largeHeight) / (smallWidth * smallHeight);
  var fill = outs / maxOuts * 100;
  return (
    fill: fill,
    outs: outs,
    layout: (
      largeHeight: largeHeight,
      largeWidth: largeWidth,
      smallWidth: smallWidth,
      smallHeight: smallHeight,
      rects: layout
    )
  );
}
