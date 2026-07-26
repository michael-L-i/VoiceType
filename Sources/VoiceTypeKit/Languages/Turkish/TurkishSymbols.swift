import Foundation

/// Turkish's spoken technical vocabulary.
///
/// This intentionally does not populate `LanguagePack.symbols`: a shared
/// integrity test reserves that declarative field for English today. Running
/// the same vocabulary from a Turkish-owned rule also repairs model output,
/// which the field-based rules floor alone could not do.
enum TurkishSymbols {
    /// Multi-word Turkish names are folded to temporary single tokens because
    /// `SpokenSymbols` is token based. Any marker that is not consumed in a
    /// proven technical shape is restored verbatim, so ordinary prose such as
    /// "alt çizgi" remains ordinary prose.
    static let renderRule = CleanupRule(
        name: "render Turkish spoken technical symbols",
        stage: .early,
        runsInTerminal: true) { text, context in
            var normalized = text

            // Noun-first bracket commands are common in Turkish dictation;
            // normalize them to the renderer's opener-first grammar.
            normalized = replace(
                normalized, "köşeli parantez aç", "aç köşeliparantez")
            normalized = replace(
                normalized, "köşeli parantez kapat", "kapat köşeliparantez")
            normalized = replace(
                normalized, "köşeli parantezi aç", "aç köşeliparantez")
            normalized = replace(
                normalized, "köşeli parantezi kapat", "kapat köşeliparantez")
            normalized = replace(normalized, "parantez aç", "aç parantez")
            normalized = replace(normalized, "parantez kapat", "kapat parantez")
            normalized = replace(normalized, "parantezi aç", "aç parantez")
            normalized = replace(normalized, "parantezi kapat", "kapat parantez")

            normalized = replace(normalized, "alt çizgi", "altçizgi")
            normalized = replace(normalized, "kısa çizgi", "kısaçizgi")
            normalized = replace(normalized, "eğik çizgi", "eğikçizgi")
            normalized = replace(normalized, "kuyruklu a", "kuyruklua")
            normalized = replace(normalized, "köşeli parantez", "köşeliparantez")

            var rendered = SpokenSymbols.render(
                normalized,
                category: context.category,
                vocabulary: vocabulary)

            // A phrase left over was not in a renderer-approved shape.
            rendered = replace(rendered, "altçizgi", "alt çizgi")
            rendered = replace(rendered, "kısaçizgi", "kısa çizgi")
            rendered = replace(rendered, "eğikçizgi", "eğik çizgi")
            rendered = replace(rendered, "kuyruklua", "kuyruklu a")
            rendered = replace(rendered, "köşeliparantez", "köşeli parantez")
            return rendered
        }

    private static let vocabulary = SpokenSymbolVocabulary(
        dot: ["nokta"],
        underscore: ["altçizgi"],
        dash: ["tire", "kısaçizgi"],
        slash: ["eğikçizgi", "bölü"],
        tilde: ["tilde"],
        comma: ["virgül"],
        emailAt: ["et", "kuyruklua"],
        openers: ["aç"],
        closers: ["kapat", "kapa"],
        parenNouns: ["parantez"],
        bracketNouns: ["köşeliparantez"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
            "lock", "env",
        ],
        extensionHomophones: [
            "ceyson": "json",
            "ceysın": "json",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov",
            "me", "tr",
        ],
        joinGuards: TurkishOrthography.stopwords,
        emailLocalGuards: TurkishOrthography.stopwords.union([
            "bak", "bakın", "git", "gel", "buluş", "görüş", "kal", "dur",
            "başla", "ulaş",
        ]))

    private static func replace(_ text: String,
                                _ phrase: String,
                                _ replacement: String) -> String {
        text.replacingOccurrences(
            of: phrase,
            with: replacement,
            options: [.caseInsensitive])
    }
}
