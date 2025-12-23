/// Minimal AuthService shim used by UI while full auth is implemented.
class AuthService {
	AuthService._();
	static final AuthService _instance = AuthService._();
	factory AuthService() => _instance;

	/// Replace this with real auth display name lookup.
	String? get currentDisplayName => null;
}
