import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/mock_profile_repository.dart';
import '../domain/repositories/profile_repository.dart';


class ProfileModule {
  const ProfileModule._();

  static List<SingleChildWidget> providers() => <SingleChildWidget>[
        Provider<ProfileRepository>(
          create: (_) => MockProfileRepository(),
        ),
      ];
}
