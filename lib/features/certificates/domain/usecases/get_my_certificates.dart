import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/certificate.dart';
import '../repositories/certificate_repository.dart';

class GetMyCertificates implements UseCase<List<Certificate>, NoParams> {
  GetMyCertificates(this._repository);
  final CertificateRepository _repository;

  @override
  Future<Result<List<Certificate>>> call(NoParams params) =>
      _repository.getMyCertificates();
}
