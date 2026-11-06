import 'package:isar_community/isar.dart';

import 'isar_models.dart';
import 'isar_service.dart';

class LessonRepository {
  static Future<int> ensureTerm({
    required int schoolYear,
    required String termName,
  }) async {
    final isar = IsarService.instance;

    final term = await isar.academicTerms
        .filter()
        .schoolYearEqualTo(schoolYear)
        .termNameEqualTo(termName)
        .findFirst();

    final activeTerm =
        term ??
        (AcademicTerm()
          ..schoolYear = schoolYear
          ..termName = termName);

    await isar.writeTxn(() async {
      if (term == null) {
        await isar.academicTerms.put(activeTerm);
      }

      final settings = await isar.appSettings.get(1) ?? (AppSettings()..id = 1);
      settings.selectedTermId = activeTerm.id;
      await isar.appSettings.put(settings);
    });

    return activeTerm.id;
  }
}
