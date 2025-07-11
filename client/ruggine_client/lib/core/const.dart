
//API paths
import 'package:ruggine_client/config.dart';

final String apibase = AppConfig.apiBaseUrl;
const String apipath_register = "auth/register";
const String apipath_login = "auth/login";
const String apipath_user = "user";

//Route constants
const String route_login = "/login";
const String route_home = "/";

// Secure Storage Keys
const String kHivePath = 'hive_path';
const String kJwtTokenKey = 'jwt_token';
const String kChatsBox = 'chats_box';
const String kInvitesBox = 'invites_box';
const String kMessagesBox = 'messages_box';