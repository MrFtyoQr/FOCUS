Raíz del proyecto
productivity_app/
│
├── 
lib/
│   ├── 
main.dart
                    # entry point — inicializa Riverpod + GoRouter
│   │
│   ├── 
core/
                        # código compartido por toda la app
│   │   ├── 
api/
│   │   │   ├── 
api_client.dart
      # instancia de Dio + interceptores
│   │   │   ├── 
api_endpoints.dart
   # constantes de todas las rutas
│   │   │   └── 
auth_interceptor.dart
 # JWT refresh silencioso
│   │   ├── 
storage/
│   │   │   ├── 
secure_storage.dart
  # flutter_secure_storage — JWT
│   │   │   └── 
local_prefs.dart
     # SharedPreferences — flags ligeros
│   │   ├── 
security/
│   │   │   └── 
biometric_service.dart
# local_auth + fallback PIN
│   │   ├── 
router/
│   │   │   └── 
app_router.dart
      # GoRouter — rutas + deep links
│   │   ├── 
theme/
│   │   │   ├── 
app_theme.dart
       # ThemeData oscuro
│   │   │   ├── 
app_colors.dart
      # colores del design system
│   │   │   └── 
app_text_styles.dart
 # tipografía
│   │   ├── 
widgets/
                 # widgets reutilizables globales
│   │   │   ├── 
app_button.dart
│   │   │   ├── 
app_input.dart
│   │   │   ├── 
activity_card.dart
   # card con badge asignada
│   │   │   ├── 
status_badge.dart
    # pill de Hoy / Mañana / etc.
│   │   │   └── 
empty_state.dart
     # estado vacío reutilizable
│   │   └── 
utils/
│   │       ├── 
date_utils.dart
│   │       └── 
string_utils.dart
│   │
│   ├── 
features/
                    # una carpeta por módulo de negocio
│   │   │
│   │   ├── 
auth/
                    # login, registro, onboarding, biometría
│   │   │   ├── 
data/
│   │   │   │   ├── 
auth_repository.dart
│   │   │   │   └── 
auth_models.dart
     # User, LoginRequest, etc.
│   │   │   ├── 
providers/
│   │   │   │   └── 
auth_provider.dart
   # Riverpod — estado de sesión
│   │   │   └── 
screens/
│   │   │       ├── 
login_screen.dart
│   │   │       ├── 
register_screen.dart
│   │   │       ├── 
onboarding_screen.dart
 # slides de bienvenida
│   │   │       ├── 
biometric_screen.dart
  # pantalla de desbloqueo
│   │   │       └── 
invite_screen.dart
     # registro desde link
│   │   │
│   │   ├── 
dashboard/
               # tablero principal
│   │   │   ├── 
data/
│   │   │   │   └── 
activity_repository.dart
│   │   │   ├── 
providers/
│   │   │   │   └── 
dashboard_provider.dart
│   │   │   └── 
screens/
│   │   │       ├── 
dashboard_screen.dart
│   │   │       └── 
activity_detail_screen.dart
│   │   │
│   │   ├── 
capture/
                 # formulario de captura
│   │   │   ├── 
providers/
│   │   │   │   └── 
capture_provider.dart
│   │   │   └── 
screens/
│   │   │       └── 
capture_screen.dart
│   │   │
│   │   ├── 
projects/
                # lista + detalle de proyecto
│   │   │   ├── 
data/
│   │   │   │   └── 
project_repository.dart
│   │   │   ├── 
providers/
│   │   │   │   └── 
projects_provider.dart
│   │   │   └── 
screens/
│   │   │       ├── 
projects_screen.dart
│   │   │       └── 
project_detail_screen.dart
 # sub-tablero
│   │   │
│   │   ├── 
stats/
                   # productividad
│   │   │   ├── 
data/
│   │   │   │   └── 
stats_repository.dart
│   │   │   ├── 
providers/
│   │   │   │   └── 
stats_provider.dart
│   │   │   └── 
screens/
│   │   │       └── 
stats_screen.dart
│   │   │
│   │   ├── 
team/
                    # equipo + asignación
│   │   │   ├── 
data/
│   │   │   │   └── 
team_repository.dart
│   │   │   ├── 
providers/
│   │   │   │   └── 
team_provider.dart
│   │   │   └── 
screens/
│   │   │       ├── 
team_screen.dart
│   │   │       └── 
assign_screen.dart
      # modal de asignación
│   │   │
│   │   └── 
profile/
                 # perfil + settings
│   │       ├── 
providers/
│   │       │   └── 
profile_provider.dart
│   │       └── 
screens/
│   │           ├── 
profile_screen.dart
│   │           └── 
security_screen.dart
    # biometría + PIN
│   │
│   └── 
shared/
                      # modelos compartidos entre features
│       ├── 
models/
│       │   ├── 
activity.dart
│       │   ├── 
project.dart
│       │   ├── 
user.dart
│       │   └── 
area.dart
│       └── 
enums/
│           ├── 
activity_status.dart
  # bandeja | hoy | manana | ...
│           └── 
user_role.dart
        # super_admin | admin_area | trabajador
│
Fuera de lib/
├── 
assets/
│   ├── 
images/
│   └── 
icons/
├── 
.env
                             # API_BASE_URL
├── 
pubspec.yaml
└── 
pubspec.lock