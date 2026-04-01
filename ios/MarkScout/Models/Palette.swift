import Foundation

enum PaletteId: String, CaseIterable, Codable {
    case parchmentDusk, deepOcean, rosewood, terminalGreen
    case warmPaper, nordFrost, monokai, solarizedDark
    case catppuccin, synthwave, dracula, tokyoNight
    case daylight, sepiaLight, arctic, sakura
}

struct Palette: Identifiable {
    let id: PaletteId
    let label: String
    let category: String
    let vars: [String: String]
}

struct PaletteCategory: Identifiable {
    let id: String
    let name: String
    let palettes: [Palette]
}

// MARK: - All 16 palettes ported from desktop

let allPalettes: [Palette] = [
    Palette(id: .parchmentDusk, label: "Parchment Dusk", category: "Dark Warm", vars: [
        "--prose-h1": "#f5e6c8", "--prose-h2": "#e8d5a3", "--prose-h3": "#d4a8a8",
        "--prose-h4": "#9aad8b", "--prose-h5": "#8a9daa", "--prose-bold": "#f5edd8",
        "--prose-italic": "#c8b5d8", "--prose-code": "#6fc4af", "--prose-blockquote": "#a89a88",
        "--prose-list-marker": "#c89838", "--prose-th": "#b89a6a",
        "--text": "#e8e0d4", "--bg": "#0d0d0d",
        "--code-bg": "#111111", "--border": "#2a2a2a", "--surface": "#161616",
    ]),
    Palette(id: .deepOcean, label: "Deep Ocean", category: "Dark Cool", vars: [
        "--prose-h1": "#7dd3fc", "--prose-h2": "#67b8f0", "--prose-h3": "#93c5fd",
        "--prose-h4": "#6ee7b7", "--prose-h5": "#a5b4fc", "--prose-bold": "#e0f2fe",
        "--prose-italic": "#c4b5fd", "--prose-code": "#34d399", "--prose-blockquote": "#64748b",
        "--prose-list-marker": "#38bdf8", "--prose-th": "#5eadd5",
        "--text": "#cdd6e4", "--bg": "#0b1022",
        "--code-bg": "#0d1330", "--border": "#1e2d4a", "--surface": "#101830",
    ]),
    Palette(id: .rosewood, label: "Rosewood", category: "Dark Warm", vars: [
        "--prose-h1": "#f0b4b4", "--prose-h2": "#e8a0a0", "--prose-h3": "#dba080",
        "--prose-h4": "#b8c898", "--prose-h5": "#a0a8c0", "--prose-bold": "#f5e0e0",
        "--prose-italic": "#d4a0c8", "--prose-code": "#e0a870", "--prose-blockquote": "#988080",
        "--prose-list-marker": "#d88888", "--prose-th": "#c89090",
        "--text": "#e8d8d4", "--bg": "#180e0e",
        "--code-bg": "#1c1010", "--border": "#3a2424", "--surface": "#201414",
    ]),
    Palette(id: .terminalGreen, label: "Terminal", category: "Dark Vibrant", vars: [
        "--prose-h1": "#4ade80", "--prose-h2": "#22c55e", "--prose-h3": "#86efac",
        "--prose-h4": "#a3e635", "--prose-h5": "#34d399", "--prose-bold": "#d9f99d",
        "--prose-italic": "#67e8f9", "--prose-code": "#4ade80", "--prose-blockquote": "#4b5563",
        "--prose-list-marker": "#22c55e", "--prose-th": "#38a85c",
        "--text": "#b8e0c4", "--bg": "#050f05",
        "--code-bg": "#061008", "--border": "#143018", "--surface": "#0a1a0c",
    ]),
    Palette(id: .warmPaper, label: "Warm Paper", category: "Dark Warm", vars: [
        "--prose-h1": "#c8a878", "--prose-h2": "#b89868", "--prose-h3": "#a88858",
        "--prose-h4": "#988060", "--prose-h5": "#887860", "--prose-bold": "#d8c8a8",
        "--prose-italic": "#b0a088", "--prose-code": "#c0a060", "--prose-blockquote": "#706050",
        "--prose-list-marker": "#a08848", "--prose-th": "#a89068",
        "--text": "#c8b898", "--bg": "#141008",
        "--code-bg": "#18140c", "--border": "#302818", "--surface": "#1c1810",
    ]),
    Palette(id: .nordFrost, label: "Nord Frost", category: "Dark Cool", vars: [
        "--prose-h1": "#88c0d0", "--prose-h2": "#81a1c1", "--prose-h3": "#5e81ac",
        "--prose-h4": "#a3be8c", "--prose-h5": "#b48ead", "--prose-bold": "#eceff4",
        "--prose-italic": "#b48ead", "--prose-code": "#8fbcbb", "--prose-blockquote": "#4c566a",
        "--prose-list-marker": "#81a1c1", "--prose-th": "#6a8bad",
        "--text": "#d8dee9", "--bg": "#0e141e",
        "--code-bg": "#111926", "--border": "#243044", "--surface": "#141c28",
    ]),
    Palette(id: .monokai, label: "Monokai", category: "Dark Vibrant", vars: [
        "--prose-h1": "#f92672", "--prose-h2": "#fd971f", "--prose-h3": "#e6db74",
        "--prose-h4": "#a6e22e", "--prose-h5": "#66d9ef", "--prose-bold": "#f8f8f2",
        "--prose-italic": "#ae81ff", "--prose-code": "#a6e22e", "--prose-blockquote": "#75715e",
        "--prose-list-marker": "#fd971f", "--prose-th": "#e09040",
        "--text": "#f8f8f2", "--bg": "#1a1a14",
        "--code-bg": "#1e1e16", "--border": "#3e3d32", "--surface": "#272822",
    ]),
    Palette(id: .solarizedDark, label: "Solarized", category: "Dark Cool", vars: [
        "--prose-h1": "#b58900", "--prose-h2": "#cb4b16", "--prose-h3": "#d33682",
        "--prose-h4": "#859900", "--prose-h5": "#268bd2", "--prose-bold": "#eee8d5",
        "--prose-italic": "#6c71c4", "--prose-code": "#2aa198", "--prose-blockquote": "#586e75",
        "--prose-list-marker": "#b58900", "--prose-th": "#a08020",
        "--text": "#c0b898", "--bg": "#002b36",
        "--code-bg": "#003340", "--border": "#094f5c", "--surface": "#073642",
    ]),
    Palette(id: .catppuccin, label: "Catppuccin", category: "Dark Vibrant", vars: [
        "--prose-h1": "#f5c2e7", "--prose-h2": "#cba6f7", "--prose-h3": "#f38ba8",
        "--prose-h4": "#a6e3a1", "--prose-h5": "#89b4fa", "--prose-bold": "#cdd6f4",
        "--prose-italic": "#f5c2e7", "--prose-code": "#94e2d5", "--prose-blockquote": "#585b70",
        "--prose-list-marker": "#cba6f7", "--prose-th": "#b8a0d8",
        "--text": "#cdd6f4", "--bg": "#121020",
        "--code-bg": "#16142a", "--border": "#2e2a48", "--surface": "#1a1830",
    ]),
    Palette(id: .synthwave, label: "Synthwave", category: "Dark Vibrant", vars: [
        "--prose-h1": "#ff2975", "--prose-h2": "#f97316", "--prose-h3": "#00e5ff",
        "--prose-h4": "#fde047", "--prose-h5": "#c084fc", "--prose-bold": "#f0d0ff",
        "--prose-italic": "#ff79c6", "--prose-code": "#00e5ff", "--prose-blockquote": "#6b4c8a",
        "--prose-list-marker": "#ff2975", "--prose-th": "#c060e0",
        "--text": "#e0d0f0", "--bg": "#0a0014",
        "--code-bg": "#0e0020", "--border": "#2a1848", "--surface": "#120028",
    ]),
    Palette(id: .dracula, label: "Dracula", category: "Dark Cool", vars: [
        "--prose-h1": "#ff79c6", "--prose-h2": "#bd93f9", "--prose-h3": "#8be9fd",
        "--prose-h4": "#50fa7b", "--prose-h5": "#ffb86c", "--prose-bold": "#f8f8f2",
        "--prose-italic": "#ff79c6", "--prose-code": "#50fa7b", "--prose-blockquote": "#6272a4",
        "--prose-list-marker": "#bd93f9", "--prose-th": "#9580c8",
        "--text": "#f8f8f2", "--bg": "#0d1117",
        "--code-bg": "#111822", "--border": "#2a3040", "--surface": "#141c28",
    ]),
    Palette(id: .tokyoNight, label: "Tokyo Night", category: "Dark Cool", vars: [
        "--prose-h1": "#7aa2f7", "--prose-h2": "#bb9af7", "--prose-h3": "#7dcfff",
        "--prose-h4": "#9ece6a", "--prose-h5": "#e0af68", "--prose-bold": "#c0caf5",
        "--prose-italic": "#bb9af7", "--prose-code": "#9ece6a", "--prose-blockquote": "#565f89",
        "--prose-list-marker": "#7aa2f7", "--prose-th": "#6a80b8",
        "--text": "#a9b1d6", "--bg": "#0d1017",
        "--code-bg": "#111620", "--border": "#1e2438", "--surface": "#131820",
    ]),
    Palette(id: .daylight, label: "Daylight", category: "Light", vars: [
        "--prose-h1": "#1a1a2e", "--prose-h2": "#2d3a4a", "--prose-h3": "#8b4513",
        "--prose-h4": "#2e7d32", "--prose-h5": "#1565c0", "--prose-bold": "#111",
        "--prose-italic": "#6a1b9a", "--prose-code": "#c62828", "--prose-blockquote": "#78909c",
        "--prose-list-marker": "#e65100", "--prose-th": "#37474f",
        "--text": "#1e1e1e", "--bg": "#fafaf8",
        "--code-bg": "#f0eeea", "--border": "#d8d4cc", "--surface": "#f2f0ec",
        "--text-muted": "#777", "--accent": "#c07820", "--active-bg": "#ece8e0", "--hover-bg": "#f5f3ef",
    ]),
    Palette(id: .sepiaLight, label: "Sepia", category: "Light", vars: [
        "--prose-h1": "#5c3d1a", "--prose-h2": "#6d4c28", "--prose-h3": "#8b5e34",
        "--prose-h4": "#4a6741", "--prose-h5": "#3e6578", "--prose-bold": "#3a2510",
        "--prose-italic": "#7a4a6a", "--prose-code": "#8b4513", "--prose-blockquote": "#8a7a68",
        "--prose-list-marker": "#a0682a", "--prose-th": "#6d5a40",
        "--text": "#3a3028", "--bg": "#f8f0e4",
        "--code-bg": "#f0e8d8", "--border": "#d8c8a8", "--surface": "#f4ecdc",
        "--text-muted": "#887868", "--accent": "#b87a30", "--active-bg": "#ece0c8", "--hover-bg": "#f6efe2",
    ]),
    Palette(id: .arctic, label: "Arctic", category: "Light", vars: [
        "--prose-h1": "#1e3a5f", "--prose-h2": "#2c5282", "--prose-h3": "#744210",
        "--prose-h4": "#276749", "--prose-h5": "#553c9a", "--prose-bold": "#1a202c",
        "--prose-italic": "#6b46c1", "--prose-code": "#2b6cb0", "--prose-blockquote": "#718096",
        "--prose-list-marker": "#2b6cb0", "--prose-th": "#2d3748",
        "--text": "#2d3748", "--bg": "#f7fafc",
        "--code-bg": "#edf2f7", "--border": "#cbd5e0", "--surface": "#eef3f8",
        "--text-muted": "#718096", "--accent": "#3182ce", "--active-bg": "#e2e8f0", "--hover-bg": "#f0f5fa",
    ]),
    Palette(id: .sakura, label: "Sakura", category: "Light", vars: [
        "--prose-h1": "#8b2252", "--prose-h2": "#6a3d6a", "--prose-h3": "#a0527a",
        "--prose-h4": "#4a7a5a", "--prose-h5": "#4a6a8a", "--prose-bold": "#3a1a2a",
        "--prose-italic": "#7a3a6a", "--prose-code": "#d45d79", "--prose-blockquote": "#b89aaa",
        "--prose-list-marker": "#c86a8a", "--prose-th": "#6a4a5a",
        "--text": "#3a2030", "--bg": "#fdf2f5",
        "--code-bg": "#f8e8ee", "--border": "#e8c8d8", "--surface": "#faeef2",
        "--text-muted": "#9a7a8a", "--accent": "#c86a8a", "--active-bg": "#f0d8e0", "--hover-bg": "#fcf0f4",
    ]),
]

let paletteCategories: [PaletteCategory] = {
    let grouped = Dictionary(grouping: allPalettes, by: \.category)
    let order = ["Dark Warm", "Dark Cool", "Dark Vibrant", "Light"]
    return order.compactMap { cat in
        guard let palettes = grouped[cat] else { return nil }
        return PaletteCategory(id: cat, name: cat, palettes: palettes)
    }
}()

func palette(for id: PaletteId) -> Palette {
    allPalettes.first { $0.id == id } ?? allPalettes[0]
}
