# 🚀 Professional Employee Management System (EMS Pro)

A production-grade, state-of-the-art SaaS platform built for modern workforce management. This system provides a seamless experience for both Administrators and Employees with real-time data persistence and a premium user interface.

---

## ✨ Features

### 🛠️ Administrator Panel
- **SaaS Dashboard**: Real-time analytics on attendance, salary expenses, and employee distribution.
- **Employee Management**: Full CRUD operations with secure credential management.
- **Department Module**: Organizes the workforce into dynamic, clickable departments.
- **Attendance Hub**: Monitor daily logs to see who is present, absent, or late.
- **Salary Lifecycle**: Manage payroll with a 3-step workflow: `Pending` ➔ `In Process` ➔ `Paid`.
- **Global Support Chat**: Centralized system to resolve employee queries in real-time.

### 📱 Employee Portal
- **Smart Check-in**: One-click attendance marking with time-tracking.
- **My Profile**: Secure view of personal details and employment role.
- **Payroll History**: Real-time visibility into salary status updates from HR.
- **Support System**: Raise queries and engage in full conversational chat with the Admin.

---

## 🗄️ Database Architecture (SQLite)

The system uses a relational **SQLite** database for lightning-fast local persistence.

| Table | Purpose |
| :--- | :--- |
| **`admins`** | Stores administrative login credentials. |
| **`employees`** | Core profiles, roles, contact info, and encrypted passwords. |
| **`departments`** | Organizational units linking employees to teams. |
| **`attendance`** | Daily check-in/out logs with status (Present/Late). |
| **`salary`** | Payroll ledger tracking amounts, dates, and payment status. |
| **`queries`** | Support ticket headers with subject and resolution status. |
| **`messages`** | Full conversation history for every support query. |

---

## 🚀 Getting Started

Follow these steps to run the project on your local machine:

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- An IDE (Android Studio or VS Code) or terminal access.
- An Android Emulator, iOS Simulator, or Chrome for Web testing.

### 2. Installation
Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/employee-management-system.git
```

Navigate to the project folder:
```bash
cd employee-management-system
```

Fetch all dependencies:
```bash
flutter pub get
```

### 3. Running the App
To run the app on your preferred device:
```bash
flutter run
```

---

## 🎨 UI/UX Design System
- **Colors**: Modern Indigo (`#4F46E5`) and Emerald (`#10B981`) palette.
- **Responsiveness**: Fully adaptive layouts that work on Web, Tablet, and Desktop.
- **Security**: Role-based data isolation ensuring employees only see their own records.
