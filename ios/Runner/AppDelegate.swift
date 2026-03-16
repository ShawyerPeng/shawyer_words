import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var dictionaryFilePickerBridge: DictionaryFilePickerBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let dictionaryFilePickerChannel = FlutterMethodChannel(
      name: "shawyer_words/dictionary_file_picker",
      binaryMessenger: messenger
    )

    dictionaryFilePickerBridge = DictionaryFilePickerBridge()

    dictionaryFilePickerChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickDictionaryPackageSource" || call.method == "pickMdxFile" else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.dictionaryFilePickerBridge?.pickDictionaryPackageSource(result: result)
    }
  }
}

private final class DictionaryFilePickerBridge: NSObject, UIDocumentPickerDelegate {
  private var pendingResult: FlutterResult?

  func pickDictionaryPackageSource(result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(
        FlutterError(
          code: "picker_busy",
          message: "A dictionary picker is already active.",
          details: nil
        )
      )
      return
    }

    guard let presenter = topViewController() else {
      result(
        FlutterError(
          code: "picker_unavailable",
          message: "Unable to find a visible view controller.",
          details: nil
        )
      )
      return
    }

    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(
        forOpeningContentTypes: [.folder, .archive, .data],
        asCopy: true
      )
    } else {
      picker = UIDocumentPickerViewController(
        documentTypes: ["public.folder", "public.data"],
        in: .import
      )
    }
    picker.delegate = self
    picker.allowsMultipleSelection = false

    pendingResult = result
    presenter.present(picker, animated: true)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(nil)
    pendingResult = nil
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let sourceURL = urls.first else {
      pendingResult?(nil)
      pendingResult = nil
      return
    }

    guard sourceURL.hasDirectoryPath || isSupportedPackageFile(sourceURL) else {
      pendingResult?(
        FlutterError(
          code: "invalid_file_type",
          message: "Please choose a dictionary folder, archive package, or single MDX file.",
          details: sourceURL.lastPathComponent
        )
      )
      pendingResult = nil
      return
    }

    let hasSecurityScope = sourceURL.startAccessingSecurityScopedResource()
    defer {
      if hasSecurityScope {
        sourceURL.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let fileManager = FileManager.default
      let targetDirectory = fileManager.temporaryDirectory.appendingPathComponent(
        "imported_dictionary_sources",
        isDirectory: true
      )
      try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)

      let targetURL = targetDirectory.appendingPathComponent(sourceURL.lastPathComponent)
      if fileManager.fileExists(atPath: targetURL.path) {
        try fileManager.removeItem(at: targetURL)
      }
      try fileManager.copyItem(at: sourceURL, to: targetURL)

      pendingResult?(targetURL.path)
    } catch {
      pendingResult?(
        FlutterError(
          code: "picker_copy_failed",
          message: "Failed to copy the selected dictionary package.",
          details: error.localizedDescription
        )
      )
    }

    pendingResult = nil
  }

  private func topViewController() -> UIViewController? {
    let connectedScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let keyWindow = connectedScenes
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }

    var current = keyWindow?.rootViewController
    while let presented = current?.presentedViewController {
      current = presented
    }
    return current
  }

  private func isSupportedPackageFile(_ url: URL) -> Bool {
    let lowercaseName = url.lastPathComponent.lowercased()
    return lowercaseName.hasSuffix(".mdx")
      || lowercaseName.hasSuffix(".zip")
      || lowercaseName.hasSuffix(".tar")
      || lowercaseName.hasSuffix(".tar.gz")
      || lowercaseName.hasSuffix(".tgz")
      || lowercaseName.hasSuffix(".tar.bz2")
      || lowercaseName.hasSuffix(".tbz")
      || lowercaseName.hasSuffix(".tar.xz")
      || lowercaseName.hasSuffix(".txz")
  }
}
