package main

import (
    "fmt"
    "os"
    "path/filepath"
    "sort"
)

var ignoredEntries = map[string]struct{}{
    ".svn":      {},
    ".git":      {},
    ".DS_Store": {},
}

type counter struct {
    dirs  int
    files int
}

func main() {
    targetDir := "."
    if len(os.Args) > 1 {
        targetDir = os.Args[1]
    }

    absPath, err := filepath.Abs(targetDir)
    if err != nil {
        fmt.Fprintf(os.Stderr, "Error getting absolute path: %v\n", err)
        os.Exit(1)
    }

    fmt.Printf("./ (%s/)\n", absPath)

    c := counter{}

    if err := printTree(targetDir, "", &c); err != nil {
        fmt.Fprintf(os.Stderr, "Error printing tree: %v\n", err)
        os.Exit(1)
    }

    fmt.Printf("\n%d directories, %d files\n", c.dirs, c.files)
}

func printTree(root, prefix string, c *counter) error {
    entries, err := os.ReadDir(root)
    if err != nil {
        return fmt.Errorf("reading directory %s: %w", root, err)
    }

    entries = filterAndSort(entries)

    for i, entry := range entries {
        isLast := i == len(entries)-1

        connector := "├── "
        newPrefix := prefix + "│   "
        if isLast {
            connector = "└── "
            newPrefix = prefix + "    "
        }

        path := filepath.Join(root, entry.Name())

        fmt.Println(prefix + connector + entry.Name())

        info, err := os.Lstat(path)
        if err != nil {
            return fmt.Errorf("getting file info for %s: %w", path, err)
        }

        if info.Mode()&os.ModeSymlink != 0 || !entry.IsDir() {
            c.files++
        } else if entry.IsDir() {
            c.dirs++
            if err := printTree(path, newPrefix, c); err != nil {
                return err
            }
        }
    }

    return nil
}

func filterAndSort(entries []os.DirEntry) []os.DirEntry {
    filtered := make([]os.DirEntry, 0, len(entries))
    for _, entry := range entries {
        if _, shouldIgnore := ignoredEntries[entry.Name()]; shouldIgnore {
            continue
        }
        filtered = append(filtered, entry)
    }

    sort.Slice(filtered, func(i, j int) bool {
        return filtered[i].Name() < filtered[j].Name()
    })

    return filtered
}
