;;; Personal configuration -*- lexical-binding: t -*-
;; Save the contents of this file under ~/.emacs.d/init.el
;; Do not forget to use Emacs' built-in help system:
;; Use C-h C-h to get an overview of all help commands.  All you
;; need to know about Emacs (what commands exist, what functions do,
;; what variables specify), the help system can provide.
;(require 'package)
;(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
;(package-initialize)

;; set SBCL as the default common lisp processer
(setq inferior-lisp-program "/usr/local/bin/sbcl")
;; add ~/.emacs.d/slime to load-path
(add-to-list 'load-path (expand-file-name "~/.emacs.d/slime"))
;; load SLIME
(require 'slime)
(slime-setup '(slime-repl slime-fancy slime-banner))

(add-to-list 'auto-mode-alist '("\\.lisp\\'" . lisp-mode))
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
