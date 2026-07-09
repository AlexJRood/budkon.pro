import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/apptheme.dart';

import 'package:get/get_utils/get_utils.dart';

class TodoNoclient extends ConsumerWidget {
  final bool isPc;
  const TodoNoclient({super.key, required this.isPc});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 55,
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: theme.clientplaceholdercolor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color.fromARGB(255, 61, 61, 61))),
                    padding: const EdgeInsets.only(
                        top: 24, bottom: 6, left: 2, right: 2),
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        height: 170,
                        decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.white54,
                                  spreadRadius: 0,
                                  blurRadius: 0,
                                  offset: Offset(1, -1))
                            ],
                            border: Border.all(
                                color: const Color.fromARGB(255, 61, 61, 61)),
                            borderRadius: BorderRadius.circular(10),
                            color: theme.textFieldColor),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 2,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Smallcontainers(
                                            height: 50, child: SizedBox()),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Smallcontainers(
                                            height: 40, child: SizedBox()),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Smallcontainers(
                                            height: 25, child: SizedBox()),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Smallcontainers(
                                          height: 150,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  color: theme.textFieldColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 30,
                                              ),
                                              Container(
                                                height: 5,
                                                width: 25,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .iconTheme
                                                      .color,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 3,
                                              ),
                                              Container(
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .iconTheme
                                                      .color!
                                                      .withAlpha((255 * 0.7).toInt()),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 3,
                                              ),
                                              Container(
                                                width: 35,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .iconTheme
                                                      .color!
                                                      .withAlpha((255 * 0.7).toInt()),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: Smallcontainers(
                                            height: 50, child: SizedBox()),
                                      ),
                                    ],
                                  ),
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: Smallcontainers(
                                            height: 40, child: SizedBox()),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Smallcontainers(
                                            height: 25, child: AppIcons.add()),
                                      ),
                                    ],
                                  ),
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )),
                  ),
                  Positioned(
                    bottom: 178,
                    left: 10,
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 25,
                      color:
                          Theme.of(context).iconTheme.color!.withAlpha((255 * 0.7).toInt()),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    bottom: 9,
                    child: Transform.rotate(
                      angle: 450 *
                          3.1415927 /
                          360, // Rotation in radians (45 degrees)

                      child: Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: theme.fillColor,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    left: 0,
                    child: Transform.rotate(
                      angle: -50 *
                          3.1415927 /
                          360, // Rotation in radians (45 degrees)

                      child: Smallcontainers(
                        height: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 15,
                            ),
                            Container(
                              width: 25,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .iconTheme
                                    .color!
                                    .withAlpha((255 * 0.7).toInt()),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            SizedBox(
                              height: 3,
                            ),
                            Container(
                              height: 5,
                              width: 35,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .iconTheme
                                    .color!
                                    .withAlpha((255 * 0.7).toInt()),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            "New Task".tr,
            style: TextStyle(color: theme.mobileTextcolor, fontSize: 15),
          ),
          const SizedBox(
            height: 5,
          ),
          isPc
              ? Text(
                  "Involves creating and assigning a new task within the project management system.".tr,
                  style: TextStyle(color: theme.mobileTextcolor, fontSize: 11))
              : SizedBox(),
          isPc
              ? const SizedBox(
                  height: 50,
                )
              : SizedBox(),
          Row(
            children: [
              Expanded(
                  child: ElevatedButton.icon(
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(theme.clientbuttoncolor),
                  shape: WidgetStatePropertyAll((RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ))),
                ),
                icon: Icon(
                  Icons.add,
                  color: theme.fillColor,
                  size: 14,
                ),
                label: Text(
                  "Add New Event".tr,
                  style: TextStyle(fontSize: 10, color: theme.fillColor),
                ),
                onPressed: () {},
              ))
            ],
          ),
          const SizedBox(
            height: 25,
          ),
        ],
      ),
    );
  }
}

class Smallcontainers extends ConsumerWidget {
  final Widget child;
  final double height;

  const Smallcontainers({super.key, required this.child, required this.height});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        height: height,
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).iconTheme.color!.withAlpha((255 * 0.7).toInt()),
                  spreadRadius: 0,
                  blurRadius: 0,
                  offset: Offset(1, -1))
            ],
            color: theme.clientplaceholdercolor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color.fromARGB(255, 61, 61, 61),
            )),
        child: child,
      ),
    );
  }
}
