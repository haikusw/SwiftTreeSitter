import Foundation
import tree_sitter

public struct Language {
    /// This is a closure whose output URL is to the directory which has the language `scm` files.
    public typealias DirectoryProvider = () -> URL

    public var tsLanguage: UnsafePointer<TSLanguage>
    public var directoryProvider: DirectoryProvider?

    /// Creates an instance.
    /// - Parameters:
    ///   - language: The language to parse.
    ///   - directoryProvider: An optional closure which would return a directory `URL` to the container of the
    ///   language's `scm` resources.
    public init(language: UnsafePointer<TSLanguage>, directoryProvider: DirectoryProvider? = nil) {
        self.tsLanguage = language
        self.directoryProvider = directoryProvider
    }

    #if !os(WASI)
    /// Creates an instance.
    /// - Parameters:
    ///   - language: The language to parse.
    ///   - languageName: The name of the language. This is used to attempt to find the embedded resource directory
    ///    for the language (which would contain files like highlights.scm).
    public init(language: UnsafePointer<TSLanguage>, name: String) {
        self.init(language: language, directoryProvider: Language.embeddedResourceProvider(named: name))
    }
    #endif
}

extension Language {
    public static var version: Int {
        return Int(TREE_SITTER_LANGUAGE_VERSION)
    }

    public static var minimumCompatibleVersion: Int {
        return Int(TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION)
    }

    public var ABIVersion: Int {
        return Int(ts_language_version(tsLanguage))
    }
    
    public var fieldCount: Int {
        return Int(ts_language_field_count(tsLanguage))
    }

    public var symbolCount: Int {
        return Int(ts_language_symbol_count(tsLanguage))
    }

    public func fieldName(for id: Int) -> String? {
        guard let str = ts_language_field_name_for_id(tsLanguage, TSFieldId(id)) else { return nil }
        
        return String(cString: str)
    }
    
    public func fieldId(for name: String) -> Int? {
        let count = UInt32(name.utf8.count)
        
        let value = name.withCString { cStr in
            return ts_language_field_id_for_name(tsLanguage, cStr, count)
        }
        
        return Int(value)
    }

    public func symbolName(for id: Int) -> String? {
        guard let str = ts_language_symbol_name(tsLanguage, TSSymbol(id)) else {
            return nil
        }

        return String(cString: str)
    }
}

extension Language: Equatable {
    public static func ==(lhs: Language, rhs: Language) -> Bool {
        return lhs.tsLanguage == rhs.tsLanguage
    }
}

public extension Language {
    var highlightsFileURL: URL? {
        return directoryProvider?().appendingPathComponent("highlights.scm")
    }

    var injectionsFileURL: URL? {
        return directoryProvider?().appendingPathComponent("injections.scm")
    }
}

#if !os(WASI)
extension Language {
    /// For languages where the resources are embedded in the app's bundle, this function returns the directory provider
    /// that finds the location of the resource's containing folder on disk. The match is fuzzy so if a Swift Package
    /// Manager's resource bundle is in use it could take the shape of `PackageName_PackageName.bundle` in which case
    /// this function only needs `PackageName` as its input to find the path to the bundle.
    ///
    /// This function also normalizes for tests so that resources can be found while under test. `Bundle.main` is different
    /// in an app context vs an XCTest context.
    /// - Parameter resourceDirectory: The name of the directory or bundle to search for embedded within the main bundle.
    /// - Returns: If found, returns the directory provider closure.
    static func embeddedResourceProvider(named resourceDirectory: String) -> Language.DirectoryProvider? {
        let fileManager = FileManager.default
        let bundle = effectiveBundle

		let foundBundleURL = try? fileManager
			.contentsOfDirectory(at: bundle.bundleURL, includingPropertiesForKeys: [.isDirectoryKey])
			.filter({ (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true })
			.first(where: { $0.lastPathComponent.contains(resourceDirectory) })

        guard
            let foundBundleURL = foundBundleURL,
            let resourceDirURL = searchForDirectoryContainingFileExtension("scm", startingIn: foundBundleURL)
        else { return nil }

        return { resourceDirURL }
    }

	private static var effectiveBundle: Bundle {
		let mainBundle = Bundle.main

		guard mainBundle.isXCTestRunner else {
			return mainBundle
		}

		let testBundle = Bundle.allBundles .first(where: {
			$0.bundlePath.components(separatedBy: "/").last?.contains("Tests.xctest") == true
		})

		return testBundle ?? mainBundle
	}

    private static func searchForDirectoryContainingFileExtension(_ ext: String, startingIn directory: URL) -> URL? {
        let fileManager = FileManager.default

		let contents = try? fileManager.contentsOfDirectory(
			at: directory,
			includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
			options: [.skipsHiddenFiles]
		)

		guard let contents = contents else { return nil }

		for item in contents {
			var isDirectory: ObjCBool = false
			fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory)

			if isDirectory.boolValue == false {
				if item.lastPathComponent.contains(ext) {
					var urlComponents = URLComponents(url: item, resolvingAgainstBaseURL: false)!
					urlComponents.path = (urlComponents.path as NSString).deletingLastPathComponent
					return urlComponents.url
				}
			} else {
				if let foundURL = searchForDirectoryContainingFileExtension(ext, startingIn: item.standardizedFileURL) {
					return foundURL
				}
			}
		}

        return nil
    }
}

private extension Bundle {
	var isXCTestRunner: Bool {
#if DEBUG
		return NSClassFromString("XCTest") != nil
#else
		return false
#endif
	}
}

public extension Language {
    /// Construct a query object from data in a file.
    func query(contentsOf url: URL) throws -> Query {
        let data = try Data(contentsOf: url)

        return try Query(language: self, data: data)
    }
}
#endif
