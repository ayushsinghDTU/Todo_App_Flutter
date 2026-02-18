# Todo_App_Flutter

# Fake News Detector (Flutter App)

Windows Flutter desktop app.

## 1) One-Time Setup (PowerShell)

Run these once in a PowerShell terminal:

```powershell
# Add Flutter + Conda to User PATH
[Environment]::SetEnvironmentVariable(
  "Path",
  [Environment]::GetEnvironmentVariable("Path","User") +
  ";C:\Users\ayush\flutter\bin;C:\Users\ayush\anaconda3;C:\Users\ayush\anaconda3\Scripts;C:\Users\ayush\anaconda3\condabin",
  "User"
)

# Initialize conda for PowerShell
& "C:\Users\ayush\anaconda3\Scripts\conda.exe" init powershell
```

After this, close VS Code fully and open it again.

## 2) Run Project (Every Time)

Open a new VS Code terminal in this project folder:

```powershell
conda activate base
flutter --version
flutter pub get
flutter run -d windows
```

## 3) If `flutter` Is Not Recognized

Use direct Flutter path:

```powershell
& "C:\Users\ayush\flutter\bin\flutter.bat" pub get
& "C:\Users\ayush\flutter\bin\flutter.bat" run -d windows
```

## 4) Build Release EXE

```powershell
flutter build windows --release
```

If PATH is not loaded:

```powershell
& "C:\Users\ayush\flutter\bin\flutter.bat" build windows --release
```

Output file:

`build\windows\x64\runner\Release\todo_app.exe`

## 5) Useful Commands

```powershell
flutter doctor
flutter clean
flutter pub outdated
```

