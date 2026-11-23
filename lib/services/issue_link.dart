/// Baut die vorausgefüllte GitHub-"New Issue"-URL für "Problem melden".
///
/// Es wird bewusst kein Token in der App hinterlegt: Das Issue wird mit dem
/// eigenen GitHub-Konto der meldenden Person im Browser abgeschickt.
const String issueRepoOwner = 'carstenroesner';
const String issueRepoName = 'tanita_anzeige';

Uri buildIssueUri({
  required bool isProblem,
  required String title,
  required String body,
}) {
  final cleanTitle = title.trim().isEmpty ? 'Ohne Titel' : title.trim();
  final cleanBody = body.trim().isEmpty ? '(keine Beschreibung)' : body.trim();
  return Uri.https(
    'github.com',
    '/$issueRepoOwner/$issueRepoName/issues/new',
    {
      'title': cleanTitle,
      'body': '$cleanBody\n\n---\nGemeldet aus der App Tanita Anzeige',
      'labels': isProblem ? 'bug' : 'enhancement',
    },
  );
}
