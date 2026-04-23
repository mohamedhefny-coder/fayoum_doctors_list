/// Public web base URL used inside QR codes.
///
/// You can override at build time using:
/// `--dart-define=PUBLIC_WEB_BASE_URL=https://your-domain/`
///
/// Default points to this repo's GitHub Pages.
const String kPublicWebBaseUrl = String.fromEnvironment(
  'PUBLIC_WEB_BASE_URL',
  defaultValue: 'https://mohamedhefny-coder.github.io/fayoum_doctors_list/',
);

Uri buildPublicRadiologyUrl({required String centerName}) {
  final base = Uri.parse(kPublicWebBaseUrl);
  return base.replace(
    queryParameters: {
      ...base.queryParameters,
      'radiology': centerName,
    },
  );
}

Uri buildPublicDoctorUrl({required String doctorId}) {
  final base = Uri.parse(kPublicWebBaseUrl);
  return base.replace(
    queryParameters: {
      ...base.queryParameters,
      'doctor': doctorId,
    },
  );
}

Uri buildPublicMedicalCenterUrl({required String centerName}) {
  final base = Uri.parse(kPublicWebBaseUrl);
  return base.replace(
    queryParameters: {
      ...base.queryParameters,
      'medical_center': centerName,
    },
  );
}

Uri buildPublicLabUrl({required String labName}) {
  final base = Uri.parse(kPublicWebBaseUrl);
  return base.replace(
    queryParameters: {
      ...base.queryParameters,
      'lab': labName,
    },
  );
}
