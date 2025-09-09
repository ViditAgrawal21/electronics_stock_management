# Electronics Stock Management

A Flutter-based application for managing electronic components inventory, PCB boards, and device assemblies. This application helps track electronic components, manage BOMs (Bill of Materials), and monitor production readiness.

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
  - Excel-based BOM import
  - BOM validation against available components
  - Component shortage tracking
  - Batch calculation for production

- **Production Planning**
  - Check production feasibility
  - Calculate material requirements
  - Track material shortages
  - Batch production planning

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

## Project Structure

```
lib/
├── main.dart
└── src/
    ├── constants/      # App constants and strings
    ├── models/         # Data models (Device, PCB, BOM)
    ├── providers/      # State management providers
    ├── screens/        # UI screens
    ├── services/       # Business logic services
    └── widgets/        # Reusable widgets
```

## Usage

1. **Creating a New Device**
   - Enter device name
   - Add components from quick-add or custom components
   - Add PCB boards
   - Upload BOMs for PCBs

2. **Managing BOMs**
   - Import BOM from Excel
   - Review component availability
   - Track missing components
   - Calculate production feasibility

3. **Production Planning**
   - Select device and quantity
   - Check component availability
   - View material requirements
   - Identify potential shortages

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
- Excel file handling libraries
- Material Design components
