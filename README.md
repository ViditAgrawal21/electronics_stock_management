# Electronics Stock Management

A comprehensive Flutter-based application for managing electronic components inventory, PCB boards, device assemblies, and production planning. This app streamlines tracking of electronic components, managing BOMs (Bill of Materials), monitoring production readiness, and includes features like user authentication, alerts for shortages, device history, and PDF report generation.

## Features

- **Device Management**
  - Create and manage electronic devices
  - Custom device naming and configuration
  - Track device components and PCBs

- **PCB Management**
  - Add multiple PCBs to devices
  - Upload and manage BOMs for each PCB
  - Track PCB components and their quantities

- **Component Management**
  - Quick-add common components
  - Custom component creation
  - Track component quantities and availability

- **BOM Management**
  - Excel-based BOM import and export
  - BOM validation against available components
  - Component shortage tracking
  - Batch calculation for production

- **Production Planning**
  - Check production feasibility
  - Calculate material requirements
  - Track material shortages
  - Batch production planning

- **User Authentication**
  - Secure login and user management
  - Role-based access control

- **Alerts and Notifications**
  - Real-time alerts for component shortages
  - Customizable notification settings

- **Device History**
  - Track changes and updates to devices
  - Historical data for auditing and analysis

- **PDF Report Generation**
  - Generate detailed reports for BOMs and production
  - Export data in PDF format for sharing

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK
- Android Studio / VS Code with Flutter plugins
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/ViditAgrawal21/electronics_stock_management.git
   ```

2. Navigate to project directory:
   ```bash
   cd electronics_stock_management
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application:
   ```bash
   flutter run
   ```

### Dependencies

This project uses several key packages (refer to `pubspec.yaml` for the full list):
- `riverpod` for state management
- `excel` for Excel file handling
- `pdf` for PDF generation
- `json_serializable` for data serialization

## Project Structure

```
lib/
├── main.dart
└── src/
    ├── constants/      # App constants, strings, and preloaded data
    │   ├── app_config.dart
    │   ├── app_string.dart
    │   └── preloaded_data.dart
    ├── models/         # Data models (Device, PCB, BOM, Materials, User)
    │   ├── bom.dart
    │   ├── bom.g.dart
    │   ├── devices.dart
    │   ├── devices.g.dart
    │   ├── materials.dart
    │   ├── materials.g.dart
    │   ├── pcb.dart
    │   ├── pcb.g.dart
    │   └── user.dart
    ├── providers/      # State management providers
    │   ├── alert_provider.dart
    │   ├── bom_provider.dart
    │   ├── device_providers.dart
    │   ├── materials_providers.dart
    │   └── pcb_providers.dart
    ├── screens/        # UI screens
    │   ├── alerts_screen.dart
    │   ├── bom_upload_screen.dart
    │   ├── device_history_screen.dart
    │   ├── home_screen.dart
    │   ├── login_screen.dart
    │   ├── materials_list_screen.dart
    │   └── pcb_creation_screen.dart
    ├── services/       # Business logic services
    │   ├── alert_services.dart
    │   ├── bom_services.dart
    │   ├── excel_service.dart
    │   ├── login_services.dart
    │   ├── pdf_services.dart
    │   └── stock_services.dart
    ├── theme/          # App theming
    │   ├── app_theme.dart
    │   └── text_styles.dart
    ├── utils/          # Utility functions
    │   ├── excel_utils.dart
    │   ├── notifier.dart
    │   ├── search_trie.dart
    │   └── validator.dart
    └── widgets/        # Reusable widgets
        ├── bom_table.dart
        ├── custom_button.dart
        ├── custom_outlined_button.dart
        ├── filter.dart
        ├── materials_card.dart
        ├── notifier.dart
        ├── search_bar.dart
        ├── stock_summary.dart
        └── validator.dart
```

## Usage

1. **User Login**
   - Launch the app and authenticate using your credentials
   - Access role-based features based on your user account

2. **Creating a New Device**
   - Enter device name
   - Add components from quick-add or custom components
   - Add PCB boards
   - Upload BOMs for PCBs

3. **Managing BOMs**
   - Import BOM from Excel
   - Review component availability
   - Track missing components
   - Calculate production feasibility

4. **Production Planning**
   - Select device and quantity
   - Check component availability
   - View material requirements
   - Identify potential shortages

5. **Viewing Alerts and History**
   - Check alerts for component shortages
   - Review device history for changes and updates
   - Generate PDF reports for BOMs and production data

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter framework and community
- Riverpod for state management
- Excel file handling libraries (e.g., `excel` package)
- PDF generation libraries (e.g., `pdf` package)
- json_serializable for data serialization
- Material Design components
