import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:izimemo/home_page/study_widget/dictionary_menu_widget_controller.dart';

import '../../custom/colors/custom_design_colors.dart';
import '../../custom/custom_constants.dart';
import '../../custom/dialogs.dart';
import '../../custom/widgets/custom_elevated_button.dart';
import '../../custom/widgets/custom_form_label.dart';
import '../../custom/widgets/custom_text_form_field.dart';

class DictionaryMenuWidget extends StatefulWidget {
  DictionaryMenuWidget({super.key});

  @override
  State<DictionaryMenuWidget> createState() => _DictionaryMenuWidgetState();
}

class _DictionaryMenuWidgetState extends State<DictionaryMenuWidget> {
  final DictionaryMenuWidgetController dictionaryMenuWidgetController = Get.put(DictionaryMenuWidgetController());

  final Dialogs dialogs = Dialogs();

  final _titleFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String? selectedMenu;

    return Obx(() {
      List<Map<String, dynamic>> dicsList = dictionaryMenuWidgetController.availableDics.value;
      return PopupMenuButton(
        initialValue: selectedMenu,
        onSelected: (value) {
          dictionaryMenuWidgetController.changeCurrentDic(value);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          ...dicsList.asMap().entries.map(
                // ...dictionaryMenuWidgetController.availableDics.value.asMap().entries.map(
                (e) => PopupMenuItem(
                  key: ValueKey(e.value['storageName']),
                  value: e.value['storageName'],
                  child: ClipRRect(
                    child: Slidable(
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.7,
                        children: [
                          SlidableAction(
                            onPressed: (BuildContext context) {
                              _titleFieldController.text = e.value['humanName']!;
                              dialogs.showDialog(
                                content: Form(
                                  child: SizedBox(
                                    height: 140,
                                    child: ListView(
                                      children: [
                                        CustomFormLabel(title: 'title'.tr, topPadding: 4),
                                        CustomTextFormField(
                                          controller: _titleFieldController,
                                          maxLength: CustomConstants.urlTitleMaxLength,
                                          maxLengthEnforcement: MaxLengthEnforcement.none,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  CustomElevatedButton(
                                    onPressed: () => dictionaryMenuWidgetController.renameDic(
                                      e.key,
                                      _titleFieldController.text,
                                    ),
                                    title: 'save'.tr,
                                  ),
                                  CustomElevatedButton(
                                    onPressed: () => Get.back(),
                                    title: 'cancel'.tr,
                                    backgroundColor: CustomDesignColors.mediumBlue,
                                    foregroundColor: CustomDesignColors.darkBlue,
                                  ),
                                ],
                              );
                            },
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey,
                            icon: Icons.edit_rounded,
                            // label: 'Edit',
                            borderRadius: BorderRadius.circular(100),
                            spacing: 0,
                            padding: EdgeInsets.zero,
                          ),
                          SlidableAction(
                            onPressed: (BuildContext context) {
                              dialogs.showDialog(
                                content: Text('you_want_reset_dic'.tr),
                                actions: [
                                  CustomElevatedButton(
                                    onPressed: () => dictionaryMenuWidgetController.deleteDic(e.key),
                                    title: 'yes'.tr,
                                    // dictionaryMenuWidgetController.deleteDic(e.key);
                                  ),
                                  CustomElevatedButton(
                                    onPressed: () => Get.back(),
                                    title: 'no'.tr,
                                    backgroundColor: CustomDesignColors.mediumBlue,
                                    foregroundColor: CustomDesignColors.darkBlue,
                                  ),
                                ],
                              );
                            },
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey,
                            icon: FontAwesomeIcons.arrowRotateLeft,
                            // label: 'Reset',
                            borderRadius: BorderRadius.circular(100),
                            spacing: 0,
                            padding: EdgeInsets.zero,
                          ),
                          (dictionaryMenuWidgetController.lengthDicsList > 1)
                              ? SlidableAction(
                                  onPressed: (BuildContext context) {
                                    dialogs.showDialog(
                                      content: Text('you_want_delete_dic'.tr),
                                      actions: [
                                        CustomElevatedButton(
                                          onPressed: () => dictionaryMenuWidgetController.deleteDic(e.key),
                                          title: 'yes'.tr,
                                          // dictionaryMenuWidgetController.deleteDic(e.key);
                                        ),
                                        CustomElevatedButton(
                                          onPressed: () => Get.back(),
                                          title: 'no'.tr,
                                          backgroundColor: CustomDesignColors.mediumBlue,
                                          foregroundColor: CustomDesignColors.darkBlue,
                                        ),
                                      ],
                                    );
                                  },
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red[200],
                                  icon: FontAwesomeIcons.trashCan,
                                  // label: 'Delete',
                                  borderRadius: BorderRadius.circular(100),
                                  spacing: 0,
                                  padding: EdgeInsets.zero,
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      child: ListTile(
                        trailing: const Icon(Icons.switch_left_rounded),
                        title: Text(e.value['humanName']),
                        minLeadingWidth: 0,
                        minVerticalPadding: 0,
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ),
                  ),
                ),
              ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'create_dictionary',
            // padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.add),
              title: Text('create_dictionary'.tr),
              minLeadingWidth: 0,
              minVerticalPadding: 0,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          ),
        ],
        elevation: 0,
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_vert,
          color: Colors.white,
        ),
        color: CustomDesignColors.menuBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(24),
          ),
        ),
      );
    });
  }
}
