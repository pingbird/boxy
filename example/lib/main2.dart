import 'package:boxy/boxy.dart';
import 'package:flutter/widgets.dart';

class TestBug extends StatelessWidget {
  const TestBug({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomBoxy(
        delegate: MyBoxy(),
        children: const [
          BoxyId<String>(
            id: 'child-0',
            data: "I'm a child",
            child: SizedBox(width: 50, height: 50),
          ),
        ],
      ),
    );
  }
}

class MyBoxy extends BoxyDelegate {
  @override
  Size layout() {
    final child = getChild('child-0');
    print(child.parentData);
    child.layout(constraints);
    print(child.parentData);
    child.position(Offset.zero);
    return constraints.biggest;
  }
}

void main() {
  runApp(const TestBug());
}
