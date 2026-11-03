import Foundation

#if os(macOS)
public enum AppEdition {
    public static let isPro: Bool = true
    public static let appName: String = "YaDiag"
    public static let bundleId: String = "com.jabella78.yadiag"
    public static let proAppStoreURL: String = ""
}
#else
public enum AppEdition {
    public static let isPro: Bool = true
    public static let appName: String = "YaDiag Pro"
    public static let bundleId: String = "com.jabella78.yadiag.pro"
    public static let proAppStoreURL: String = ""
}
#endif
