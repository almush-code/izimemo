import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';

import '../../app_storage/app_settings_storage.dart';
import '../../app_storage/dictionary_storage.dart';
import '../../custom/colors/custom_lesson_colors.dart';

class DictionaryController extends GetxController {
  final DictionaryStorage dictionaryStorage = DictionaryStorage();
  final AppSettingsStorage appSettingsStorage = AppSettingsStorage();
  final LineSplitter lineSplitter = const LineSplitter();

  late RxInt lastCreatedDicIndex;
  late RxString lastOpenedDic;
  late RxList<Map<String, dynamic>> availableDics;
  late RxInt lengthDicsList;
  late RxInt firstElementCurrentDic;

  var autoPlay = true.obs;

  List<String> get getCurrentWordsList => dictionaryStorage.readWordListByDicKey(dictionaryStorage.readLastOpenedDic);
  late RxList<String> currentWordsList;
  List<String> get getSliderWordList => _wordListGenerator(
        dictionaryStorage.readWordListByDicKey(dictionaryStorage.readLastOpenedDic),
        dictionaryStorage.readFirstElementForDictionary(dictionaryStorage.readLastOpenedDic),
        appSettingsStorage.readEntriesInLesson.round(),
      );
  late RxList<String> sliderWordList;
  List<int> get getSlideColorIndexList => _slideColorListGenerator(sliderWordList.length);
  late RxList<int> slideColorIndexList;
  double get getSecondsPerEntries => appSettingsStorage.readSecondsPerEntries;
  late RxDouble secondsPerEntries;

  late List<String> _learnedWords;
  late List<String> _learningWords;
  late List<String> _willLearnWords;

  RxInt carouselInitialPage = 0.obs;
  int indexCurrentSlide = 0;

  late RxBool lastEntry;

  DictionaryController() {
    lastCreatedDicIndex = dictionaryStorage.readLastCreatedDicIndex.obs;
    lastOpenedDic = dictionaryStorage.readLastOpenedDic.obs;
    availableDics = dictionaryStorage.readAvailableDics.obs;
    lengthDicsList = availableDics.length.obs;
    firstElementCurrentDic = dictionaryStorage.readFirstElementForDictionary(dictionaryStorage.readLastOpenedDic).obs;

    sliderWordList = getSliderWordList.obs;
    slideColorIndexList = getSlideColorIndexList.obs;
    currentWordsList = getCurrentWordsList.obs;
    secondsPerEntries = getSecondsPerEntries.obs;
  }

  void _updateInitialData() {
    sliderWordList.value = getSliderWordList;
    slideColorIndexList.value = getSlideColorIndexList;
    currentWordsList.value = getCurrentWordsList;
  }

  //
  // MENU
  //

  void changeCurrentDic(String currentDic) {
    lastOpenedDic.value = currentDic;
    dictionaryStorage.writeLastOpenedDic(currentDic);

    _updateInitialData();
  }

  void renameDic(int dicIndex, String newDicName) {
    availableDics[dicIndex]['humanName'] = newDicName;
    dictionaryStorage.writeAvailableDics(availableDics);
    Get.back();
    Get.back();
  }

  void deleteDic(int dicIndex) {
    String dicKey = availableDics[dicIndex]['storageName'];

    // Delete dic and their index
    dictionaryStorage.deleteWordListByDicKey(dicKey);
    dictionaryStorage.deleteFirstElementForDictionary(dicKey);

    // Delete info about dic in description list in storage
    availableDics.removeAt(dicIndex);
    dictionaryStorage.writeAvailableDics(availableDics);

    //If deleted dic is current dic?
    if (dicKey == lastOpenedDic.value) {
      lastOpenedDic.value = availableDics[0]['storageName'];
      dictionaryStorage.writeLastOpenedDic(lastOpenedDic.value);
      firstElementCurrentDic.value = dictionaryStorage.readFirstElementForDictionary(lastOpenedDic.value);
    }

    // It will be impossible to delete dic when one left
    lengthDicsList.value = availableDics.length;

    _updateInitialData();

    Get.back();
    Get.back();
  }

  void resetDic(String storageName) {
    dictionaryStorage.writeFirstElementForDictionary(storageName, 0);
    firstElementCurrentDic.value = 0;

    _updateInitialData();
    carouselInitialPage.value = 0;

    Get.back();
    Get.back();
  }

  void addDic(String newDicName, String newEntries) {
    lastCreatedDicIndex++;
    dictionaryStorage.writeLastCreatedDicIndex(lastCreatedDicIndex.value);

    String storageDicName = 'dic_${lastCreatedDicIndex.value}';

    Map<String, dynamic> newDicDescription = {
      'storageName': storageDicName,
      'humanName': newDicName,
    };

    availableDics.add(newDicDescription);
    dictionaryStorage.writeAvailableDics(availableDics);

    lastOpenedDic.value = storageDicName;
    dictionaryStorage.writeLastOpenedDic(lastOpenedDic.value);

    var tmpList = cleanAndSplitString(newEntries);
    if (tmpList.isEmpty) {
      tmpList = ['word_translation'.tr];
    }
    dictionaryStorage.writeWordListByDicKey(lastOpenedDic.value, tmpList);
    dictionaryStorage.writeFirstElementForDictionary(lastOpenedDic.value, 0);

    _updateInitialData();

    Get.back();
    Get.back();
  }

  //
  // STUDY
  //

  void playPause() {
    autoPlay.value = !autoPlay.value;
    carouselInitialPage.value = indexCurrentSlide;
  }

  List<String> _wordListGenerator(List<String> inputList, int firstElement, int elementsInLesson) {
    if ((firstElement + elementsInLesson) > inputList.length) {
      return inputList.sublist(firstElement);
    } else {
      return inputList.sublist(
        firstElement,
        firstElement + elementsInLesson,
      );
    }
  }

  List<int> _slideColorListGenerator(int sliderLength) {
    var random = Random();
    var colorLimit = CustomLessonColors.values.length;
    List<int> outputList = [];
    outputList.add(random.nextInt(colorLimit));
    int i;
    while (outputList.length < sliderLength) {
      do {
        i = random.nextInt(colorLimit);
      } while (i == outputList[(outputList.length - 1)]);
      outputList.add(i);
    }
    return outputList;
  }

  void _splitWordsList() {
    if (currentWordsList.isNotEmpty) {
      // _learnedWords list
      if (firstElementCurrentDic.value == 0) {
        _learnedWords = [];
      } else {
        // _learnedWords = currentWordsList.sublist(0, (firstElementCurrentDic.value - 1));
        _learnedWords = currentWordsList.sublist(0, (firstElementCurrentDic.value));
      }

      // _willLearnWords list
      int entriesInLesson = appSettingsStorage.readEntriesInLesson.round();
      if ((firstElementCurrentDic.value + entriesInLesson) >= currentWordsList.length) {
        _willLearnWords = [];
      } else {
        _willLearnWords = currentWordsList.sublist((firstElementCurrentDic.value + entriesInLesson));
      }

      // _learningWords list
      _learningWords = sliderWordList;
    } else {
      _learnedWords = [];
      _learningWords = [];
      _willLearnWords = [];
    }
  }

  void _joinSaveUpdateDic() {
    firstElementCurrentDic.value = _learnedWords.length;
    dictionaryStorage.writeFirstElementForDictionary(lastOpenedDic.value, firstElementCurrentDic.value);
    List<String> tmpList = [
      ..._learnedWords,
      ..._learningWords,
      ..._willLearnWords,
    ];
    dictionaryStorage.writeWordListByDicKey(lastOpenedDic.value, tmpList);

    _updateInitialData();
  }

  void learnedEntry(int index) {
    _splitWordsList();
    _learnedWords.add(_learningWords[index]);
    _learningWords.removeAt(index);
    if (_willLearnWords.isNotEmpty) {
      _learningWords.insert(0, _willLearnWords[0]);
      _willLearnWords.removeAt(0);
    }
    _joinSaveUpdateDic();
    carouselInitialPage.value = 0;
  }

  void moveEntry(int index) {
    _splitWordsList();
    _willLearnWords.add(_learningWords[index]);
    _learningWords.removeAt(index);
    _learningWords.insert(0, _willLearnWords[0]);
    _willLearnWords.removeAt(0);
    _joinSaveUpdateDic();
    carouselInitialPage.value = 0;
  }

  void deleteEntry(int index) {
    _splitWordsList();
    _learningWords.removeAt(index);
    if (_willLearnWords.isNotEmpty) {
      _learningWords.insert(0, _willLearnWords[0]);
      _willLearnWords.removeAt(0);
    }
    _joinSaveUpdateDic();
    carouselInitialPage.value = 0;
  }

  void editEntry(int index, String replaceString) {
    _splitWordsList();
    _learningWords[index] = replaceString;
    _joinSaveUpdateDic();
    carouselInitialPage.value = index;
  }

  void addEntries(String rawString) {
    var tmpList = cleanAndSplitString(rawString);
    _splitWordsList();
    _learningWords = [
      ...tmpList,
      ..._learningWords,
    ];
    _joinSaveUpdateDic();
    carouselInitialPage.value = 0;
  }

  List<String> cleanAndSplitString(String multiRowString) {
    var tmpList = lineSplitter.convert(multiRowString);
    tmpList.removeWhere((element) => element.length < 5);
    return tmpList;
  }
}

    // print('>>> 1) _learnedWords: $_learnedWords');
    // print('>>> 1) _learningWords: $_learningWords');
    // print('>>> 1) _willLearnWords Begin: ${_willLearnWords.sublist(0, 4)}');
    // print('>>> 1) _willLearnWords End: ${_willLearnWords.sublist((_willLearnWords.length - 4))}');
    // print('>>> 1) : $');
    // print('>>> 1) : $');
    // print('>>> 2) _learnedWords: $_learnedWords');
    // print('>>> 2) _learningWords: $_learningWords');
    // print('>>> 2) _willLearnWords Begin: ${_willLearnWords.sublist(0, 4)}');
    // print('>>> 2) _willLearnWords End: ${_willLearnWords.sublist((_willLearnWords.length - 4))}');
