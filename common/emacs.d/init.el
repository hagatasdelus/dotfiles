;;; Personal configuration -*- lexical-binding: t -*-
;; Save the contents of this file under ~/.emacs.d/init.el
;; Do not forget to use Emacs' built-in help system:
;; Use C-h C-h to get an overview of all help commands.  All you
;; need to know about Emacs (what commands exist, what functions do,
;; what variables specify), the help system can provide.
;(require 'package)
;(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
;(package-initialize)

(eval-and-compile
  (customize-set-variable
   'package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                       ("melpa" . "https://melpa.org/packages/")))
  (package-initialize)
  (use-package leaf :ensure t)

  (leaf leaf-keywords
    :ensure t
    :init
    (leaf blackout :ensure t)
    :config
    (leaf-keywords-init)))

(leaf leaf-convert
  :doc "Convert many format to leaf format"
  :ensure t)

(leaf cus-edit
  :doc "tools for customizing Emacs and Lisp packages"
  :custom `((custom-file . ,(locate-user-emacs-file "custom.el"))))

(leaf cus-start
  :doc "define customization properties of builtins"
  :preface
  (defun c/redraw-frame nil
    (interactive)
    (redraw-frame))

  :bind (("M-ESC ESC" . c/redraw-frame))
  :custom '((user-full-name . "Yoshiki Horinaka")
            (user-mail-address . "hagatasdelus@gmail.com")
            (user-login-name . "hagatasdelus")
            (create-lockfiles . nil)
            (tab-width . 4)
            (debug-on-error . t)
            (init-file-debug . t)
            (frame-resize-pixelwise . t)
            (enable-recursive-minibuffers . t)
            (history-length . 1000)
            (history-delete-duplicates . t)
            (scroll-preserve-screen-position . t)
            (scroll-conservatively . 100)
            (mouse-wheel-scroll-amount . '(1 ((control) . 5)))
            (ring-bell-function . 'ignore)
            (text-quoting-style . 'straight)
            (truncate-lines . t)
            (use-dialog-box . nil)
            (use-file-dialog . nil)
            (menu-bar-mode . t)
            (tool-bar-mode . nil)
            (scroll-bar-mode . nil)
            (indent-tabs-mode . nil))
  :config
  (defalias 'yes-or-no-p 'y-or-n-p)
  (keyboard-translate ?\C-h ?\C-?))

(leaf autorevert
  :doc "revert buffers when files on disk change"
  :global-minor-mode global-auto-revert-mode)

(leaf delsel
  :doc "delete selection if you insert"
  :global-minor-mode delete-selection-mode)

(leaf paren
  :doc "highlight matching paren"
  :global-minor-mode show-paren-mode)

(leaf simple
  :doc "basic editing commands for Emacs"
  :custom ((kill-read-only-ok . t)
           (kill-whole-line . t)
           (eval-expression-print-length . nil)
           (eval-expression-print-level . nil)))

(leaf files
  :doc "file input and output commands for Emacs"
  :global-minor-mode auto-save-visited-mode
  :custom `((auto-save-file-name-transforms . '((".*" ,(locate-user-emacs-file "backup/") t)))
            (backup-directory-alist . '((".*" . ,(locate-user-emacs-file "backup"))
                                        (,tramp-file-name-regexp . nil)))
            (version-control . t)
            (delete-old-versions . t)
            (auto-save-visited-interval . 1)))

(leaf startup
  :doc "process Emacs shell arguments"
  :custom `((auto-save-list-file-prefix . ,(locate-user-emacs-file "backup/.saves-"))))

(leaf savehist
  :doc "Save minibuffer history"
  :custom `((savehist-file . ,(locate-user-emacs-file "savehist")))
  :global-minor-mode t)

(leaf flymake
  :doc "A universal on-the-fly syntax checker"
  :bind ((prog-mode-map
          ("M-n" . flymake-goto-next-error)
          ("M-p" . flymake-goto-prev-error))))

(leaf which-key
  :doc "Display available keybindings in popup"
  :ensure t
  :global-minor-mode t)

(leaf exec-path-from-shell
  :doc "Get environment variables such as $PATH from the shell"
  :ensure t
  :defun (exec-path-from-shell-initialize)
  :custom ((exec-path-from-shell-check-startup-files)
           (exec-path-from-shell-variables . '("PATH" "GOPATH" "JAVA_HOME")))
  :config
  (exec-path-from-shell-initialize))

(leaf ns
  :doc "next/open/gnustep / macos communication module"
  :when (eq 'ns window-system)
  :custom ((ns-control-modifier . 'control)
           (ns-option-modifier . 'super)
           (ns-command-modifier . 'meta)
           (ns-right-control-modifier . 'control)
           (ns-right-option-modifier . 'hyper)
           (ns-right-command-modifier . 'meta)
           (default-frame-alist . '((ns-appearance . dark)
                                    (ns-transparent-titlebar . t)))))

(leaf vertico
  :doc "VERTical Interactive COmpletion"
  :ensure t
  :global-minor-mode t)

(leaf marginalia
  :doc "Enrich existing commands with completion annotations"
  :ensure t
  :global-minor-mode t)

(leaf consult
  :doc "Consulting completing-read"
  :ensure t
  :hook (completion-list-mode-hook . consult-preview-at-point-mode)
  :defun consult-line
  :preface
  (defun c/consult-line (&optional at-point)
    "Consult-line uses things-at-point if set C-u prefix."
    (interactive "P")
    (if at-point
        (consult-line (thing-at-point 'symbol))
      (consult-line)))
  :custom ((xref-show-xrefs-function . #'consult-xref)
           (xref-show-definitions-function . #'consult-xref)
           (consult-line-start-from-top . t))
  :bind (;; C-c bindings (mode-specific-map)
         ([remap switch-to-buffer] . consult-buffer) ; C-x b
         ([remap project-switch-to-buffer] . consult-project-buffer) ; C-x p b

         ;; M-g bindings (goto-map)
         ([remap goto-line] . consult-goto-line)    ; M-g g
         ([remap imenu] . consult-imenu)            ; M-g i
         ("M-g f" . consult-flymake)

         ;; C-M-s bindings
         ("C-s" . c/consult-line)       ; isearch-forward
         ("C-M-s" . nil)                ; isearch-forward-regexp
         ("C-M-s s" . isearch-forward)
         ("C-M-s C-s" . isearch-forward-regexp)
         ("C-M-s r" . consult-ripgrep)

         (minibuffer-local-map
          :package emacs
          ("C-r" . consult-history))))

(leaf affe
  :doc "Asynchronous Fuzzy Finder for Emacs"
  :ensure t
  :custom ((affe-highlight-function . 'orderless-highlight-matches)
           (affe-regexp-function . 'orderless-pattern-compiler))
  :bind (("C-M-s r" . affe-grep)
         ("C-M-s f" . affe-find)))

(leaf orderless
  :doc "Completion style for matching regexps in any order"
  :ensure t
  :custom ((completion-styles . '(orderless))
           (completion-category-defaults . nil)
           (completion-category-overrides . '((file (styles partial-completion))))))

(leaf embark-consult
  :doc "Consult integration for Embark"
  :ensure t
  :bind ((minibuffer-mode-map
          :package emacs
          ("M-." . embark-dwim)
          ("C-." . embark-act))))

(leaf corfu
  :doc "COmpletion in Region FUnction"
  :ensure t
  :global-minor-mode global-corfu-mode corfu-popupinfo-mode
  :custom ((corfu-auto . t)
           (corfu-auto-delay . 0)
           (corfu-auto-prefix . 1)
           (corfu-popupinfo-delay . nil)) ; manual
  :bind ((corfu-map
          ("C-s" . corfu-insert-separator))))

(leaf cape
  :doc "Completion At Point Extensions"
  :ensure t
  :config
  (add-to-list 'completion-at-point-functions #'cape-file))

(leaf eglot
  :doc "The Emacs Client for LSP servers"
  :hook ((clojure-mode-hook . eglot-ensure))
  :custom ((eldoc-echo-area-use-multiline-p . nil)
           (eglot-connect-timeout . 600)))

(leaf eglot-booster
  :when (executable-find "emacs-lsp-booster")
  :vc ( :url "https://github.com/jdtsmith/eglot-booster")
  :global-minor-mode t)

(leaf puni
  :doc "Parentheses Universalistic"
  :ensure t
  :global-minor-mode puni-global-mode
  :bind (puni-mode-map
         ;; default mapping
         ;; ("C-M-f" . puni-forward-sexp)
         ;; ("C-M-b" . puni-backward-sexp)
         ;; ("C-M-a" . puni-beginning-of-sexp)
         ;; ("C-M-e" . puni-end-of-sexp)
         ;; ("M-)" . puni-syntactic-forward-punct)
         ;; ("C-M-u" . backward-up-list)
         ;; ("C-M-d" . backward-down-list)
         ("C-)" . puni-slurp-forward)
         ("C-}" . puni-barf-forward)
         ("M-(" . puni-wrap-round)
         ("M-s" . puni-splice)
         ("M-r" . puni-raise)
         ("M-U" . puni-splice-killing-backward)
         ("M-z" . puni-squeeze))
  :config
  (leaf elec-pair
    :doc "Automatic parenthesis pairing"
    :global-minor-mode electric-pair-mode))

(leaf cider
  :doc "Clojure Interactive Development Environment that Rocks"
  :ensure t)

(leaf vim-jp-radio
  :vc ( :url "https://github.com/vim-jp-radio/vim-jp-radio.el"))

;; (provide 'init)

;; set SBCL as the default common lisp processer
(setq inferior-lisp-program "/usr/local/bin/sbcl")
;; add ~/.emacs.d/slime to load-path
(add-to-list 'load-path (expand-file-name "~/.emacs.d/slime"))
;; load SLIME
(require 'slime)
(slime-setup '(slime-repl slime-fancy slime-banner slime-indentation))

;;; Slime for common lisp
; (load (expand-file-name "~/.roswell/helper.el"))  ; slime 起動スクリプト
;; (setq slime-lisp-implementations
;;       `((ros ("ros" "run"))                       ; ros run の起動設定
;;         (sbcl ("/opt/local/bin/sbcl"))
;;         (abcl ("/opt/local/bin/abcl"))
;;         (clisp ("/opt/local/bin/clisp"))))

;; Load a custom theme
; (load-theme 'tango t)

;;; Completion framework
; (unless (package-installed-p 'vertico)
;   (package-install 'vertico))

;; Enable completion by narrowing
; (vertico-mode t)

;;; Extended completion utilities
; (unless (package-installed-p 'consult)
;   (package-install 'consult))

;; Enable line numbering in `prog-mode'
; (add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Automatically pair parentheses
; (electric-pair-mode t)

;;; LSP Support
; (unless (package-installed-p 'eglot)
;   (package-install 'eglot))

;; Enable LSP support by default in programming buffers
; (add-hook 'prog-mode-hook #'eglot-ensure)

;;; Inline static analysis

;; Enabled inline static analysis
; (add-hook 'prog-mode-hook #'flymake-mode)

;;; Pop-up completion
; (unless (package-installed-p 'corfu)
;   (package-install 'corfu))

;; Enable autocompletion by default in programming buffers
; (add-hook 'prog-mode-hook #'corfu-mode)

;;; Git client
; (unless (package-installed-p 'magit)
;   (package-install 'magit))

;; Bind the `magit-status' command to a convenient key.
; (global-set-key (kbd "C-c g") #'magit-status)

;;; Indication of local VCS changes
; (unless (package-installed-p 'diff-hl)
;   (package-install 'diff-hl))

;; Enable `diff-hl' support by default in programming buffers
; (add-hook 'prog-mode-hook #'diff-hl-mode)

;;; Clojure Support
; (unless (package-installed-p 'clojure-mode)
;   (package-install 'clojure-mode))

;;; Elixir Support
; (unless (package-installed-p 'elixir-mode)
;   (package-install 'elixir-mode))

;;; Haskell Support
; (unless (package-installed-p 'haskell-mode)
;   (package-install 'haskell-mode))

;;; Lua Support
; (unless (package-installed-p 'lua-mode)
;   (package-install 'lua-mode))

;;; Markdown support
; (unless (package-installed-p 'markdown-mode)
;   (package-install 'markdown-mode))

;;; Outline-based notes management and organizer

;;; Jump to arbitrary positions
; (unless (package-installed-p 'avy)
;   (package-install 'avy))
; (global-set-key (kbd "C-c z") #'avy-goto-word-1)

;;; Vim Emulation
; (unless (package-installed-p 'evil)
;   (package-install 'evil))

;; Enable Vim emulation in programming buffers
; (add-hook 'prog-mode-hook #'evil-local-mode)

;; Miscellaneous options
;; (setq-default major-mode
;;               (lambda () ; guess major mode from file name
;;                 (unless buffer-file-name
;;                   (let ((buffer-file-name (buffer-name)))
;;                     (set-auto-mode)))))
;; (setq confirm-kill-emacs #'yes-or-no-p)
;; (setq window-resize-pixelwise t)
;; (setq frame-resize-pixelwise t)
;; (save-place-mode t)
;; (savehist-mode t)
;; (recentf-mode t)
;; (defalias 'yes-or-no #'y-or-n-p)
;;
;; ;; Store automatic customisation options elsewhere
;; (setq custom-file (locate-user-emacs-file "custom.el"))
;; (when (file-exists-p custom-file)
;;   (load custom-file))
