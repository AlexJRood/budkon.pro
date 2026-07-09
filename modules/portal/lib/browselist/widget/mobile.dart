import 'package:flutter/material.dart';
import 'package:portal/screens/feed/components/browselist/components/button.dart';
import 'package:portal/screens/feed/components/browselist/components/list.dart';


class BrowseListMobileWidget extends StatefulWidget {
  final bool isWhiteSpaceNeeded;
  const BrowseListMobileWidget({super.key, 
  this.isWhiteSpaceNeeded = false,
  });

  @override
  BrowseListMobileWidgetState createState() => BrowseListMobileWidgetState();
}

class BrowseListMobileWidgetState extends State<BrowseListMobileWidget> {



  @override
  Widget build(BuildContext context) {
    // Pełna szerokość widgetu oraz szerokość, gdy widget jest „schowany”
    double screenWidth = MediaQuery.of(context).size.width;
    


    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: screenWidth,
      // AnimatedContainer dostosowuje szerokość, dzięki czemu pozostała część UI rozszerzy się, gdy widget się zwęża.
      child: Stack(
        children: [
            BrowseListWidget(isWhiteSpaceNeeded: widget.isWhiteSpaceNeeded, isHidden: false, isMobile: true,),
            Positioned(
                top: 65,
                right: 5,
            child: BrowseListActionsWidget(isHidden: true, toggleIsHidden: (){})
          ),
        ],
      ),
    );
  }
}
