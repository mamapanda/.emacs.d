;;; Init.el Setup  -*- lexical-binding: t -*-
;;;; Startup Optimizations
(defvar panda--pre-init-file-name-handler-alist file-name-handler-alist
  "The value of `file-name-handler-alist' before init.el was loaded.")

(defvar panda--pre-init-gc-cons-threshold gc-cons-threshold
  "The value of `gc-cons-threshold' before init.el was loaded.")

(defun panda--restore-init-optimization-variables ()
  "Restore variables that were modified for init time optimization."
  (setq file-name-handler-alist panda--pre-init-file-name-handler-alist
        gc-cons-threshold panda--pre-init-gc-cons-threshold))

(setq file-name-handler-alist nil
      gc-cons-threshold 64000000)

(add-hook 'after-init-hook #'panda--restore-init-optimization-variables)

;;;; Package Management
(setq package-enable-at-startup nil
      straight-check-for-modifications '(check-on-save find-when-checking))

;; https://github.com/raxod502/straight.el#getting-started
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(require 'use-package)
(setq straight-use-package-by-default t)

;;;; Early Load Packages
(require 'cl-lib)

(use-package general
  :config
  (defalias 'gsetq 'general-setq)
  (defalias 'gsetq-default 'general-setq-default)
  (defalias 'gsetq-local 'general-setq-local))

(use-package no-littering)

(use-package hydra
  :config
  (gsetq hydra-look-for-remap t))

;;;; Custom File
(gsetq custom-file (no-littering-expand-etc-file-name "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;;;; Private Data
(defvar panda-private-file (no-littering-expand-etc-file-name "private.el")
  "File for private/sensitive configuration values.
It should contain an alist literal for `panda-get-private-data'.")

(defun panda-get-private-data (key)
  "Get the private configuration value corresponding to KEY."
  (let ((data (with-temp-buffer
                (insert-file-contents panda-private-file)
                (read (buffer-string)))))
    (alist-get key data)))

;;; Evil
;; Prevent goto-chg and undo-tree from being installed.
(cl-pushnew 'goto-chg straight-built-in-pseudo-packages)
(cl-pushnew 'undo-tree straight-built-in-pseudo-packages)

(use-package evil
  :init
  (gsetq evil-respect-visual-line-mode t
         evil-want-keybinding nil)
  :config
  (gsetq evil-disable-insert-state-bindings t
         evil-jumps-cross-buffers nil
         evil-move-beyond-eol t
         evil-toggle-key "C-s-+"
         evil-want-C-d-scroll t
         evil-want-C-u-scroll t
         evil-want-Y-yank-to-eol t)
  (gsetq-default evil-symbol-word-search t)
  (general-create-definer panda-space
    :states '(normal operator motion visual)
    :keymaps 'override
    :prefix "SPC"
    :prefix-map 'panda-space-map)
  (add-hook 'prog-mode-hook #'hs-minor-mode)
  (evil-mode 1))

(use-package evil-collection
  :config
  (gsetq evil-collection-key-blacklist '("SPC"))
  (delete 'company evil-collection-mode-list)
  (delete 'outline evil-collection-mode-list)
  (evil-collection-init))

(use-package targets
  :straight (:type git :host github :repo "noctuid/targets.el")
  :config
  (progn
    (defun panda-show-reg-targets-fix (orig-fn)
      "Advice to not error with `targets--reset-position'."
      (let ((register-alist (cl-remove 'targets--reset-position
                                       register-alist
                                       :key #'car)))
        (funcall orig-fn)))
    (advice-add #'evil-show-registers :around #'panda-show-reg-targets-fix))
  (targets-setup t))

;;; Basic Configuration
;;;; Definitions
;;;;; Defuns
(defun panda-format-buffer ()
  "Indent the entire buffer and delete trailing whitespace."
  (interactive)
  (let ((inhibit-message t))
    (indent-region (point-min) (point-max))
    (delete-trailing-whitespace)))

(defun panda-kill-this-buffer ()
  "Kill the current buffer."
  (interactive)
  (kill-buffer (current-buffer)))

(defun panda-reload-file ()
  "Reload the current file, preserving point."
  (interactive)
  (if buffer-file-name
      (let ((pos (point)))
        (find-alternate-file buffer-file-name)
        (goto-char pos))
    (message "Buffer is not visiting a file")))

(defun panda-configure-image-view ()
  "Configure settings for viewing an image."
  (display-line-numbers-mode -1)
  (gsetq-local evil-default-cursor (list nil)))

(defun panda-static-evil-ex (&optional initial-input)
  "`evil-ex' that doesn't move point."
  (interactive)
  (save-excursion (call-interactively #'evil-ex)))

(defun panda-sudo-reload-file ()
  "Reload the current file with root privileges, preserving point."
  (interactive)
  (if buffer-file-name
      (let ((pos (point)))
        (find-alternate-file (concat "/sudo:root@localhost:" buffer-file-name))
        (goto-char pos))
    (message "Buffer is not visiting a file")))

;;;;; Hooks
(defun panda--run-mode-hack-hook ()
  "Run the current major mode's `hack-local-variables' hook."
  (run-hooks (intern (format "%s-hack-hook" major-mode))))

(add-hook 'hack-local-variables-hook #'panda--run-mode-hack-hook)

;;;;; Macros
(defmacro panda-add-hook-once (hook fn &optional append local)
  "Same as `add-hook', but FN is removed from HOOK after being run."
  (let ((hook-fn-name (gensym)))
    `(progn
       (defun ,hook-fn-name ()
         (funcall ,fn)
         (remove-hook ,hook (quote ,hook-fn-name) ,local))
       (add-hook ,hook (quote ,hook-fn-name) ,append ,local))))

(cl-defmacro panda-with-gui (&body body)
  "Run BODY when a gui is available."
  (declare (indent defun))
  (if (daemonp)
      `(add-to-list 'after-make-frame-functions
                    (lambda (frame)
                      (with-selected-frame frame
                        ,@body)))
    `(progn ,@body)))

;;;;; Minor Modes
(define-minor-mode panda-format-on-save-mode
  "Indents a buffer and trims whitespace on save."
  :init-value nil
  :lighter "panda-format"
  (if panda-format-on-save-mode
      (add-hook 'before-save-hook #'panda-format-buffer nil t)
    (remove-hook 'before-save-hook #'panda-format-buffer t)))

(define-minor-mode panda-trim-on-save-mode
  "Trims whitespace on save."
  :init-value nil
  :lighter "panda-trim"
  (if panda-trim-on-save-mode
      (add-hook 'before-save-hook #'delete-trailing-whitespace nil t)
    (remove-hook 'before-save-hook #'delete-trailing-whitespace t)))

;;;;; Text Objects
;;;;;; Buffer
(evil-define-text-object panda-outer-buffer (count beg end type)
  "Select the whole buffer."
  :type line
  (evil-range (point-min) (point-max)))

(defalias 'panda-inner-buffer 'panda-outer-buffer)

;; We could define a remote buffer object that prompts for a buffer
;; and switches to it, but I don't see myself using that outside of
;; cases already covered by :read.

;;;;;; Defun
(defvar-local panda-inner-defun-bounds '("{" . "}")
  "Variable to determine the bounds of an inner defun.
The value can be a pair of regexps to determine the start and end,
exclusive of the matched expressions.  It can also be a function, in
which case the return value will be used.")

(defun panda--in-sexp-p  (pos)
  "Check if POS is inside a sexp."
  (save-excursion
    (goto-char pos)
    (condition-case nil
        (progn
          (up-list 1 t t)
          t)
      (scan-error nil))))

(defun panda--inner-defun-bounds (defun-begin defun-end open-regexp close-regexp)
  "Find the beginning and end of an inner defun.
DEFUN-BEGIN and DEFUN-END are the bounds of the defun.  OPEN-REGEXP
and CLOSE-REGEXP match the delimiters of the inner defun."
  ;; Some default parameter values (e.g. "{") can conflict with the open regexp.
  ;; However, they're usually nested in some sort of sexp, while the intended
  ;; match usually isn't.  For the close regexp, I can't think of a single
  ;; conflict case, since it's usually also the function's end.
  (save-excursion
    (save-match-data
      (let ((begin (progn
                     (goto-char defun-begin)
                     (re-search-forward open-regexp defun-end)
                     (while (save-restriction
                              (narrow-to-region defun-begin defun-end)
                              (panda--in-sexp-p (match-beginning 0)))
                       (re-search-forward open-regexp defun-end))
                     (skip-chars-forward "[:blank:]")
                     (when (eolp)
                       (forward-char))
                     (point)))
            (end (progn
                   (goto-char defun-end)
                   (re-search-backward close-regexp defun-begin)
                   (skip-chars-backward "[:blank:]")
                   (when (bolp)
                     (backward-char))
                   (point))))
        (cons begin end)))))

(defun panda--shrink-inner-defun (range)
  "Shrink RANGE to that of an inner defun."
  (cl-destructuring-bind (begin . end)
      (cond
       ((consp panda-inner-defun-bounds)
        (panda--inner-defun-bounds (evil-range-beginning range)
                                   (evil-range-end range)
                                   (car panda-inner-defun-bounds)
                                   (cdr panda-inner-defun-bounds)))
       ((functionp panda-inner-defun-bounds)
        (funcall panda-inner-defun-bounds
                 (evil-range-beginning range)
                 (evil-range-end range))))
    (evil-range begin end
                (and (= (char-before begin) (char-after end) ?\n) 'line))))

(put 'defun 'targets-no-extend t)     ; seems like defun doesn't work otherwise
(put 'defun 'targets-shrink-inner-op #'panda--shrink-inner-defun)

(targets-define-to defun 'defun nil object :linewise t :bind t :keys "d")

;;;;;; Whitespace
(defun forward-panda-whitespace (count)
  "Move forward COUNT horizontal whitespace blocks."
  (evil-forward-chars "[:blank:]" count))

(defun panda--shrink-inner-whitespace (range)
  "Shrink RANGE to not include the first whitespace character."
  (evil-set-range-beginning range (1+ (evil-range-beginning range))))

(put 'panda-whitespace 'targets-no-extend t) ; doesn't make sense to extend
(put 'panda-whitespace 'targets-shrink-inner-op #'panda--shrink-inner-whitespace)

(targets-define-to whitespace 'panda-whitespace nil object :bind t :keys " ")

;;;;;; Whitespace Line
;; The remote text object doesn't pick up a block at the beginning of
;; the buffer, even though the regular/last objects work just fine.
(defun forward-panda-whitespace-line (count)
  "Move forward COUNT whitespace-only lines."
  (condition-case nil
      (evil-forward-not-thing 'evil-paragraph count)
    (wrong-type-argument))) ; might happen at the end of the buffer

(defun panda--shrink-inner-whitespace-line (range)
  "Shrink RANGE to not include the trailing newline."
  (evil-set-range-end range (1- (evil-range-end range))))

(put 'panda-whitespace-line 'targets-no-extend t) ; doesn't make sense to extend
(put 'panda-whitespace-line 'targets-shrink-inner-op #'panda--shrink-inner-whitespace-line)

(targets-define-to whitespace-line 'panda-whitespace-line nil object
                   :bind t :keys "\^M" :linewise t)

;;;; Settings
(gsetq auto-save-default nil
       blink-cursor-blinks 0
       c-default-style '((java-mode . "java")
                         (awk-mode . "awk")
                         (other . "stroustrup"))
       default-frame-alist '((fullscreen . maximized)
                             (font . "Consolas-11")
                             (menu-bar-lines . 0)
                             (tool-bar-lines . 0)
                             (vertical-scroll-bars . nil))
       delete-by-moving-to-trash t
       disabled-command-function nil
       enable-recursive-minibuffers t
       inhibit-compacting-font-caches t
       inhibit-startup-screen t
       make-backup-files nil
       recentf-max-saved-items 100
       require-final-newline t
       ring-bell-function 'ignore
       save-abbrevs nil
       tramp-default-method "ssh"
       undo-limit 1000000
       use-dialog-box nil
       vc-follow-symlinks t
       visible-bell nil)

(gsetq-default bidi-display-reordering nil
               buffer-file-coding-system 'utf-8
               c-basic-offset 4
               fill-column 80
               indent-tabs-mode nil
               tab-width 4
               truncate-lines nil)

(blink-cursor-mode)
(delete-selection-mode 1)
(desktop-save-mode)
(electric-pair-mode 1)
(global-auto-revert-mode t)
(recentf-mode 1)
(show-paren-mode 1)

(cl-pushnew 'evil-markers-alist desktop-locals-to-save)

;; evil stores global markers in the default value of `evil-markers-alist'.
(defvar panda--default-markers-alist nil)
(cl-pushnew 'panda--default-markers-alist desktop-globals-to-save)
(add-hook 'desktop-save-hook
          (lambda ()
            (setq panda--default-markers-alist (default-value 'evil-markers-alist))))
(add-hook 'desktop-after-read-hook
          (lambda ()
            (setf (default-value 'evil-markers-alist) panda--default-markers-alist)))

;;;; Keybindings
(general-def '(normal motion) override
  ";" 'panda-static-evil-ex
  ":" 'eval-expression
  "," 'execute-extended-command
  "Q" 'save-buffer)

(general-def 'normal
  "C-r" nil
  "g;" nil
  "g," nil
  "gD" 'xref-find-references
  "[e" 'previous-error
  "]e" 'next-error)

(general-def 'insert
  "<C-backspace>" 'evil-delete-backward-word
  "C-x r i" 'evil-paste-from-register
  "M-o" 'evil-execute-in-normal-state)

(general-def 'motion
  "SPC" nil
  ";" nil
  "," nil
  "`" 'evil-goto-mark-line
  "'" 'evil-goto-mark
  "gs" 'evil-repeat-find-char
  "gS" 'evil-repeat-find-char-reverse
  "M-h" 'beginning-of-defun
  "M-l" 'end-of-defun
  "H" 'backward-sexp
  "L" 'forward-sexp)

(general-def 'outer
  "e" 'panda-outer-buffer)

(general-def 'inner
  "e" 'panda-inner-buffer)

(panda-space
  "b" 'switch-to-buffer                 ; C-x b
  "c" 'compile
  "d" 'dired                            ; C-x d
  "f" 'find-file                        ; C-x C-f
  "h" 'help-command                     ; C-h
  "o" 'occur                            ; M-s o
  "t" 'bookmark-jump                    ; C-x r b
  "T" 'bookmark-set                     ; C-x r m
  "%" (general-key "C-x C-q")           ; C-x C-q
  "-" 'delete-trailing-whitespace
  "=" 'panda-format-buffer)

(setf (cdr evil-ex-completion-map) (cdr (copy-keymap minibuffer-local-map)))
(general-def evil-ex-completion-map
  "<escape>" 'minibuffer-keyboard-quit
  "TAB" 'evil-ex-completion
  "C-x r i" 'evil-paste-from-register)

(evil-ex-define-cmd "bk[ill]" #'panda-kill-this-buffer)

;;; Global Packages
;;;; Appearance
(use-package doom-themes
  :config
  (panda-with-gui (load-theme 'doom-vibrant t)))

(use-package display-line-numbers
  :demand t
  :general (panda-space "l" 'panda-toggle-line-numbers)
  :config
  (progn
    (gsetq display-line-numbers-type 'visual)
    (defun panda-toggle-line-numbers ()
      "Toggle between `display-line-numbers-type' and absolute line numbers.
The changes are local to the current buffer."
      (interactive)
      (gsetq display-line-numbers
             (if (eq display-line-numbers display-line-numbers-type)
                 t
               display-line-numbers-type))))
  (progn
    (defun panda--evil-ex-relative-lines (old-fn &optional initial-input)
      "Enable relative line numbers for `evil-ex'."
      (let ((current-display-line-numbers display-line-numbers)
            (buffer (current-buffer)))
        (unwind-protect
            (progn
              (gsetq display-line-numbers 'relative)
              (funcall old-fn initial-input))
          (when (buffer-live-p buffer)
            (with-current-buffer buffer
              (gsetq display-line-numbers current-display-line-numbers))))))
    (advice-add 'evil-ex :around #'panda--evil-ex-relative-lines))
  (progn
    (panda-with-gui
      (global-display-line-numbers-mode 1))
    (column-number-mode 1)))

(use-package doom-modeline
  :config
  (gsetq doom-modeline-buffer-file-name-style 'relative-from-project
         doom-modeline-icon nil
         doom-modeline-unicode-fallback nil)
  (panda-with-gui
    (set-face-attribute 'doom-modeline-bar nil
                        :background (face-attribute 'mode-line :background))
    (set-face-attribute 'doom-modeline-inactive-bar nil
                        :background (face-attribute 'mode-line-inactive :background)))
  (doom-modeline-mode 1))

(use-package hl-todo
  :config
  (global-hl-todo-mode))

(use-package posframe
  :defer t
  :config
  (gsetq posframe-mouse-banish nil)
  (set-face-background 'internal-border (face-foreground 'font-lock-comment-face)))

(use-package rainbow-delimiters
  :ghook 'prog-mode-hook)

;;;; Editing
(use-package evil-args
  :general
  ('inner "a" 'evil-inner-arg)
  ('outer "a" 'evil-outer-arg))

(use-package evil-exchange
  :config
  (evil-exchange-install))

(use-package evil-indent-plus
  :config
  (evil-indent-plus-default-bindings))

(use-package evil-goggles
  :config
  (gsetq evil-goggles-pulse nil)
  (defun panda-evil-goggles-add (cmd based-on-cmd)
    "Register CMD with evil-goggles using BASED-ON-CMD's configuration."
    (when-let ((cmd-config (alist-get based-on-cmd evil-goggles--commands)))
      (add-to-list 'evil-goggles--commands (cons cmd cmd-config))
      (when (bound-and-true-p evil-goggles-mode)
        (evil-goggles-mode 1))))
  (evil-goggles-use-diff-refine-faces)
  (evil-goggles-mode 1))

(use-package evil-lion
  :general
  ('normal "gl" 'evil-lion-left
           "gL" 'evil-lion-right))

(use-package evil-nerd-commenter
  :general
  ('normal "gc" 'evilnc-comment-operator
           "gy" 'evilnc-copy-and-comment-operator)
  ('inner "c" 'evilnc-inner-comment)
  ('outer "c" 'evilnc-outer-commenter))

(use-package evil-numbers
  :general
  ('normal "C-a" 'evil-numbers/inc-at-pt
           "C-s" 'evil-numbers/dec-at-pt))

(use-package evil-owl
  :straight (evil-owl
             :host nil
             :repo "git@github.com:mamapanda/evil-owl.git"
             :local-repo "~/code/emacs-lisp/evil-owl")
  :custom-face
  (evil-owl-group-name ((t (
                            :inherit font-lock-function-name-face
                            :weight bold
                            :underline t))))
  (evil-owl-entry-name ((t (:inherit font-lock-function-name-face))))
  :config
  (gsetq evil-owl-display-method 'posframe
         evil-owl-global-mark-format " %m: [l: %-5l, c: %-5c] %b\n  %s"
         evil-owl-local-mark-format " %m: [l: %-5l, c: %-5c]\n  %s"
         evil-owl-register-char-limit 50
         evil-owl-idle-delay 0.2)
  (gsetq evil-owl-extra-posframe-args
         `(
           :poshandler posframe-poshandler-point-bottom-left-corner
           :width 50
           :height 20
           :internal-border-width 2))
  (evil-owl-mode))

(use-package evil-replace-with-register
  :general ('normal "gR" 'evil-replace-with-register))

(use-package evil-surround
  :config
  (general-def 'visual evil-surround-mode-map
    "s" 'evil-surround-region
    "S" 'evil-Surround-region
    "gS" nil)
  (global-evil-surround-mode 1))

(use-package evil-traces
  :straight (evil-traces
             :host nil
             :repo "git@github.com:mamapanda/evil-traces.git"
             :local-repo "~/code/emacs-lisp/evil-traces")
  :config
  (defun panda-no-ex-range-and-arg-p ()
    "Return non-nil if both `evil-ex-range' and `evil-ex-argument' are nil."
    (and (null evil-ex-range) (null evil-ex-argument)))
  (gsetq evil-traces-suspend-function #'panda-no-ex-range-and-arg-p)
  (evil-traces-use-diff-faces)
  (evil-traces-mode))

(use-package expand-region
  :general ('visual "v" 'er/expand-region))

(use-package undo-propose
  :general ('normal "U" 'undo-propose))

;;;; Help
(use-package helpful
  :general
  (help-map "f" 'helpful-callable
            "k" 'helpful-key
            "v" 'helpful-variable))

;;;; Navigation
(use-package avy
  :general ('motion "C-SPC" 'avy-goto-char-timer)
  :config
  (gsetq avy-all-windows nil
         avy-all-windows-alt t
         avy-background t))

(use-package deadgrep
  :general (panda-space "s" 'deadgrep)
  :config
  (defun panda-deadgrep-project-root ()
    "Find the root directory of the current project."
    (require 'projectile)
    (or (projectile-project-root) default-directory))
  (gsetq deadgrep-project-root-function #'panda-deadgrep-project-root))

(use-package evil-matchit
  :config
  (global-evil-matchit-mode 1))

(use-package evil-snipe
  :config
  (gsetq evil-snipe-repeat-keys t
         evil-snipe-smart-case t
         evil-snipe-scope 'visible
         evil-snipe-repeat-scope 'visible
         evil-snipe-tab-increment t)
  (general-def 'motion evil-snipe-override-local-mode-map
    ";" nil
    "," nil
    "gs" 'evil-snipe-repeat
    "gS" 'evil-snipe-repeat-reverse)
  (setf (cdr evil-snipe-parent-transient-map) nil)
  (general-def evil-snipe-parent-transient-map
    "s" 'evil-snipe-repeat
    "S" 'evil-snipe-repeat-reverse)
  (evil-snipe-mode 1)
  (evil-snipe-override-mode 1))

(use-package goto-last-change
  :straight (goto-last-change
             :host github
             :repo "camdez/goto-last-change.el"
             :fork (:host nil :repo "git@github.com:mamapanda/goto-last-change.el.git"))
  :general ('normal "g;" 'goto-last-change))

(use-package imenu
  :general (panda-space "i" 'imenu)
  :config
  (gsetq imenu-auto-rescan t))

(use-package projectile
  :defer t
  :general (panda-space "p" '(:keymap projectile-command-map))
  :config
  (gsetq projectile-indexing-method 'alien)
  (projectile-mode))

;;;; UI
(use-package helm
  :demand t
  :general
  (general-def
    [remap execute-extended-command] 'helm-M-x
    [remap find-file] 'helm-find-files
    [remap switch-to-buffer] 'helm-mini)
  (panda-space "S" 'helm-grep-do-git-grep)
  :config
  (gsetq helm-echo-input-in-header-line t
         ;; helm-ff-DEL-up-one-level-maybe t ; doesn't update the prompt
         helm-ff-fuzzy-matching nil
         helm-ff-skip-boring-files t
         helm-split-window-inside-p t
         helm-mini-default-sources '(helm-source-buffers-list
                                     helm-source-projectile-files-list
                                     helm-source-recentf
                                     helm-source-buffer-not-found))
  (set-face-foreground 'helm-ff-directory (face-foreground 'font-lock-builtin-face))
  (general-def helm-map "<escape>" 'helm-keyboard-quit)
  (with-eval-after-load 'projectile
    (setq projectile-completion-system 'helm))
  (helm-mode 1))

(use-package helm-company
  :after company helm
  :general
  (general-def company-active-map
    "M-h" 'helm-company)
  :init
  (gsetq helm-company-fuzzy-match nil))

(use-package helm-lsp
  :after helm lsp
  :general
  (general-def lsp-mode-map
    [remap lsp-ui-find-workspace-symbol] 'helm-lsp-workspace-symbol))

(use-package helm-make
  :after helm
  :general
  (panda-space "C" 'helm-make))

(use-package helm-projectile
  :after helm
  :init
  (gsetq helm-projectile-fuzzy-match nil)
  :config
  (helm-projectile-toggle 1))

(use-package helm-xref :after helm xref)

;;;; Windows
(use-package eyebrowse
  :demand t
  :general
  (panda-space
    "<tab>" 'eyebrowse-last-window-config
    "w" 'eyebrowse-switch-to-window-config
    "W" 'eyebrowse-close-window-config
    "e" 'panda-eyebrowse-create-window-config
    "E" 'eyebrowse-rename-window-config)
  ('normal eyebrowse-mode-map
           "gt" 'eyebrowse-next-window-config
           "gT" 'eyebrowse-prev-window-config)
  :init
  (defvar eyebrowse-mode-map (make-sparse-keymap))
  :config
  (gsetq eyebrowse-new-workspace t)
  (defun panda-eyebrowse-create-window-config (tag)
    (interactive "sWindow Config Tag: ")
    (eyebrowse-create-window-config)
    (let ((created-config (eyebrowse--get 'current-slot)))
      (eyebrowse-rename-window-config created-config tag)))
  (with-eval-after-load 'doom-modeline
    (doom-modeline-def-segment workspace-name
      "Custom workspace segment for doom-modeline."
      (when eyebrowse-mode
        (assq-delete-all 'eyebrowse-mode mode-line-misc-info)
        (let ((segment-face (if (doom-modeline--active)
                                'doom-modeline-buffer-path
                              'mode-line-inactive))
              (current-face (if (doom-modeline--active)
                                'doom-modeline-buffer-file
                              'mode-line-inactive)))
          (format
           " %s "
           (mapconcat
            (lambda (window-config)
              (let ((slot (cl-first window-config))
                    (tag (cl-third window-config)))
                (if (= slot (eyebrowse--get 'current-slot))
                    (propertize (format "%d:%s" slot tag) 'face current-face)
                  (propertize (format "%d%.1s" slot tag) 'face segment-face))))
            (eyebrowse--get 'window-configs)
            (propertize "|" 'face segment-face)))))))
  (eyebrowse-mode 1))

(use-package winner
  :demand t
  :general
  (panda-space
    "q" 'winner-undo
    "Q" 'winner-redo)
  :config
  (winner-mode 1))

;;; Tools
;;;; File Manager
(use-package image-dired
  :defer t
  :gfhook ('image-dired-display-image-mode-hook 'panda-configure-image-view)
  :general (panda-space "D" 'image-dired))

(use-package dired-filter
  :defer t
  :general ('normal dired-mode-map "gf" '(:keymap dired-filter-map)))

(use-package dired-open
  :general ('normal dired-mode-map "<C-return>" 'dired-open-xdg))

(use-package dired-subtree
  :general
  ('normal dired-mode-map
           "zo" 'panda-dired-subtree-insert
           "zc" 'panda-dired-subtree-remove
           "za" 'dired-subtree-toggle
           "<tab>" 'dired-subtree-cycle)
  :config
  (defun panda-dired-subtree-insert ()
    "Like `dired-subtree-insert', but doesn't move point."
    (interactive)
    (save-excursion
      (dired-subtree-insert)))
  (defun panda-dired-subtree-remove ()
    "Like `dired-subtree-remove', but removes the current node's children."
    (interactive)
    (when (dired-subtree--is-expanded-p)
      (dired-next-line 1)
      (dired-subtree-remove))))

(use-package dired-ranger
  :general
  ('normal dired-mode-map
           "gc" 'dired-ranger-copy
           "gm" 'dired-ranger-move
           "gp" 'dired-ranger-paste))

;;;; Git
(use-package magit
  :general (panda-space "g" 'magit-status)
  :config
  (gsetq magit-auto-revert-mode nil))

(use-package magit-todos
  :after magit
  :config
  (gsetq magit-todos-rg-extra-args '("--hidden" "--glob" "!.git/"))
  (magit-todos-mode))

(use-package forge :after magit)

(use-package evil-magit :after magit)

(use-package git-timemachine
  :general (panda-space "G" 'git-timemachine))

;;;; Music
(use-package emms
  :straight nil ; yay -S emms-git
  :general (panda-space "m" 'emms)
  :config
  (require 'emms-setup)
  (require 'emms-info-libtag)
  (emms-all)
  (defun panda-emms-track-description (track)
    "Return a description of TRACK.
This is adapted from `emms-info-track-description'."
    (let ((artist (emms-track-get track 'info-artist))
          (title (emms-track-get track 'info-title)))
      (cond ((and artist title) (concat title " - " artist))
            (title title)
            (t (emms-track-simple-description track)))))
  (gsetq emms-info-functions '(emms-info-libtag)
         emms-player-list '(emms-player-vlc)
         emms-repeat-playlist t
         emms-source-file-default-directory "~/Music"
         emms-source-file-directory-tree-function 'emms-source-file-directory-tree-find
         emms-track-description-function 'panda-emms-track-description))

;;;; Readers
(use-package elfeed
  :defer t
  :config
  (gsetq elfeed-feeds (panda-get-private-data 'elfeed-feeds)
         elfeed-search-title-max-width 100
         elfeed-search-filter "@1-month-ago +unread"))

(use-package image-mode
  :straight nil
  :defer t
  :gfhook 'panda-configure-image-view)

(use-package nov
  :mode ("\\.epub$" . nov-mode)
  :gfhook 'visual-line-mode
  :config
  (gsetq nov-text-width most-positive-fixnum))

(use-package pdf-tools
  :mode ("\\.pdf$" . pdf-view-mode)
  :gfhook ('pdf-view-mode-hook 'panda-configure-image-view)
  :config
  (gsetq-default pdf-view-display-size 'fit-page)
  (pdf-tools-install))

;;;; Shell
(use-package eshell
  :general
  (panda-space "<return>" 'eshell)
  :config
  (gsetq eshell-hist-ignoredups t
         eshell-history-size 1024))

(use-package esh-autosuggest
  :ghook 'eshell-mode-hook)

(use-package fish-completion
  :ghook 'eshell-mode-hook)

;;;; System
(use-package disk-usage :defer t)

;;; Mode-Specific Configuration
;;;; Completion / Linting
(use-package company
  :defer t
  :config
  (gsetq company-backends (delete 'company-dabbrev company-backends)
         company-dabbrev-code-modes nil
         company-idle-delay 0.2
         company-minimum-prefix-length 2
         company-tooltip-align-annotations t))

(use-package flycheck
  :defer t
  :config
  (gsetq flycheck-display-errors-delay 0.5)
  (general-def 'normal flycheck-mode-map
    "[e" 'flycheck-previous-error
    "]e" 'flycheck-next-error)
  (evil-declare-motion 'flycheck-previous-error)
  (evil-declare-motion 'flycheck-next-error))

(use-package flycheck-posframe
  :ghook 'flycheck-mode-hook
  :config
  (flycheck-posframe-configure-pretty-defaults))

;;;; Formatting
(use-package reformatter)

;;;; Keybindings
(use-package major-mode-hydra
  :demand t
  :general
  ('(normal visual) "\\" 'major-mode-hydra)
  :config
  (gsetq major-mode-hydra-invisible-quit-key "<escape>"))

;;;; Language Server
(use-package lsp-mode
  :defer t
  :commands lsp-register-client
  :config
  (gsetq lsp-auto-execute-action nil
         lsp-before-save-edits nil
         lsp-enable-indentation nil
         lsp-enable-on-type-formatting nil
         lsp-prefer-flymake nil)
  ;; LSP hooks onto xref, but these functions are more reliable.
  (general-def 'normal lsp-mode-map
    "gd" 'lsp-find-definition
    "gD" 'lsp-find-references))

(use-package company-lsp
  :after company lsp
  :config
  (gsetq company-lsp-cache-candidates 'auto))

(use-package lsp-ui
  :after lsp
  :config
  (gsetq lsp-ui-sideline-show-diagnostics nil))

(use-package dap-mode
  :commands dap-debug dap-hydra
  :config
  (require 'dap-chrome)
  (require 'dap-firefox)
  (require 'dap-gdb-lldb)
  (require 'dap-go)
  (require 'dap-python)
  (dap-mode 1)
  (dap-ui-mode 1))

(with-eval-after-load 'major-mode-hydra
  (defvar panda--lsp-hydra-enabled-modes nil
    "Major modes that already have lsp hydra heads.")
  (defun panda--add-lsp-hydra-heads ()
    "Add `lsp' command heads to the current major mode's `major-mode-hydra'."
    (unless (memq major-mode panda--lsp-hydra-enabled-modes)
      (eval
       `(major-mode-hydra-define+ ,major-mode nil
          ("Find"
           (("s" lsp-ui-find-workspace-symbol "workspace symbol"))
           "Refactor"
           (("r" lsp-rename "rename")
            ("c" lsp-ui-sideline-apply-code-actions "code action")
            ("o" lsp-organize-imports "organize imports"))
           "View"
           (("i" lsp-ui-imenu "imenu")
            ("l" lsp-lens-mode "lens")
            ("E" lsp-ui-flycheck-list "errors"))
           "Debug"
           (("D" dap-debug "start")
            ("d" dap-hydra "hydra"))
           "Workspace"
           (("<backspace>" lsp-restart-workspace "restart")
            ("<delete>" lsp-shutdown-workspace "shutdown")))))
      (push major-mode panda--lsp-hydra-enabled-modes)))
  (add-hook 'lsp-mode-hook #'panda--add-lsp-hydra-heads))

;;;; Lisp
(use-package lispyville
  :defer t
  :config
  (lispyville-set-key-theme '(c-w
                              commentary
                              operators
                              prettify
                              slurp/barf-cp))
  (general-unbind 'motion lispyville-mode-map "{" "}")
  (with-eval-after-load 'evil-goggles
    (panda-evil-goggles-add #'lispyville-yank #'evil-yank)
    (panda-evil-goggles-add #'lispyville-delete #'evil-delete)
    (panda-evil-goggles-add #'lispyville-change #'evil-change)
    (panda-evil-goggles-add #'lispyville-yank-line #'evil-yank-line)
    (panda-evil-goggles-add #'lispyville-delete-line #'evil-delete-line)
    (panda-evil-goggles-add #'lispyville-change-line #'evil-change-line)
    (panda-evil-goggles-add #'lispyville-change-whole-line #'evil-change-whole-line)
    (panda-evil-goggles-add #'lispyville-join #'evil-join)))

(use-package lispy
  :ghook 'lispyville-mode-hook
  :config
  (lispy-set-key-theme '(lispy special))
  (lispy-define-key lispy-mode-map-special "<" 'lispy-slurp-or-barf-left)
  (lispy-define-key lispy-mode-map-special ">" 'lispy-slurp-or-barf-right)
  (general-def lispy-mode-map-lispy "\"" 'lispy-doublequote))

;;;; Snippets
(use-package yasnippet
  :config
  (gsetq yas-triggers-in-field t
         yas-indent-line 'auto
         yas-also-auto-indent-first-line t)
  (yas-reload-all)
  (with-eval-after-load 'company
    (defun panda--company-yas-tab-advice (old-func &rest args)
      (unless (and (bound-and-true-p yas-minor-mode) (yas-expand))
        (call-interactively old-func args)))
    (when-let ((company-tab-func (lookup-key company-active-map (kbd "<tab>"))))
      (advice-add company-tab-func :around #'panda--company-yas-tab-advice))))

;;;; View / Layout
(use-package olivetti :defer t)

(use-package outshine
  :defer t
  :config
  (gsetq outshine-org-style-global-cycling-at-bob-p t)
  (general-def 'normal outshine-mode-map
    "<tab>" (lookup-key outshine-mode-map (kbd "TAB"))
    "<backtab>" 'outshine-cycle-buffer))

;;; Languages
;;;; Assembly
(use-package asm-mode
  :defer t
  :gfhook '(asmfmt-on-save-mode panda-set-asm-locals yas-minor-mode)
  :config
  (gsetq asm-comment-char ?#)
  (defun panda-set-asm-locals ()
    (gsetq-local indent-tabs-mode t)
    (gsetq-local tab-always-indent (default-value 'tab-always-indent)))
  (progn
    (defvar asmfmt-args nil
      "Arguments for asmfmt.")
    (reformatter-define asmfmt
      :program "asmfmt"
      :args asmfmt-args)))

;;;; C / C++
(use-package cc-mode
  :defer t
  :gfhook ('(c-mode-hook c++-mode-hook)
           '(clang-format-on-save-mode panda-set-c-locals yas-minor-mode))
  :config
  (defun panda-set-c-locals ()
    (c-set-offset 'innamespace 0))
  (progn
    (defvar clang-format-args nil
      "Arguments for clang-format.")
    (reformatter-define clang-format
      :program "clang-format"
      :args clang-format-args)))

(use-package ccls
  :ghook ('(c-mode-hook c++-mode-hook) 'panda-ccls)
  :mode-hydra
  ((c-mode c++-mode)
   nil
   ("View"
    (("p" ccls-preprocess-file "preprocess file")
     ("m" ccls-member-hierarchy "member hierarchy")
     ("C" ccls-call-hierarchy "call hierarchy")
     ("I" ccls-inheritance-hierarchy "inheritance hierarchy"))))
  :config
  ;; FIXME: It makes more sense to set this on a project-by-project
  ;; basis, but we'd have to figure out how to apply dir-local
  ;; variables before hooks are run.  Alternatively, we could try to
  ;; find compile_commands.json somehow while not having a huge
  ;; performance impact.
  (defun panda-ccls ()
    "Try to set some ccls variables, then call `lsp'."
    (catch 'break
      (when-let ((project-root (or (lsp-workspace-root buffer-file-name)
                                   (locate-dominating-file "." "CMakeLists.txt"))))
        (dolist (dir-name '("build" "debug" "release"))
          (let ((compilation-dir (expand-file-name dir-name project-root)))
            (when (file-directory-p compilation-dir)
              (setq-local ccls-initialization-options
                          `(:compilationDatabaseDirectory ,compilation-dir))
              (throw 'break t))))))
    (lsp)))

(use-package highlight-doxygen
  :ghook ('(c-mode-hook c++-mode-hook) 'highlight-doxygen-mode)
  :config
  (custom-set-faces '(highlight-doxygen-comment ((t nil)))))

;;;; Common Lisp
(use-package lisp-mode
  :straight nil
  :defer t
  :gfhook '(company-mode
            lispyville-mode
            panda-format-on-save-mode
            panda-set-lisp-locals)
  :config
  (defun panda-set-lisp-locals ()
    (setq panda-inner-defun-bounds '("(" . ")"))))

(use-package slime
  :defer t
  :mode-hydra
  (lisp-mode
   nil
   ("Eval"
    (("eb" slime-eval-buffer "buffer")
     ("ed" slime-eval-defun "defun")
     ("ee" slime-eval-last-expression "expression")
     ("er" slime-eval-region "region")
     ("eo" slime "open repl"))
    "Debug"
    (("m" macrostep-expand "macrostep"))))
  :config
  (gsetq inferior-lisp-program "sbcl"
         slime-contribs '(slime-fancy))
  (slime-setup))

(use-package slime-company
  :after slime
  :config
  (slime-company-init))

;;;; D
(use-package d-mode
  :defer t
  :gfhook '(company-mode dfmt-on-save-mode flycheck-mode yas-minor-mode)
  ;; :gfhook '(dfmt-on-save-mode lsp)
  :config
  ;; dls fails to report some errors, while serve-d doesn't even work.
  (progn
    (lsp-register-client
     (make-lsp-client :new-connection (lsp-stdio-connection '("dls"))
                      :major-modes '(d-mode)
                      :server-id 'dls))
    (add-to-list 'lsp-language-id-configuration '(d-mode . "d")))
  (progn
    (defvar dfmt-args '("--brace_style=otbs"
                        "--space_after_cast=false"
                        "--max_line_length=80")
      "Arguments for dfmt.")
    (reformatter-define dfmt
      :program "dfmt"
      :args dfmt-args)))

(use-package company-dcd :ghook 'd-mode-hook)

(use-package flycheck-dmd-dub
  :ghook ('d-mode-hook 'flycheck-dmd-dub-set-variables))

;;;; Emacs Lisp
(use-package elisp-mode
  :straight nil
  :defer t
  :gfhook ('emacs-lisp-mode-hook '(company-mode
                                   lispyville-mode
                                   panda-format-on-save-mode
                                   panda-set-elisp-locals
                                   yas-minor-mode))
  :mode-hydra
  ((emacs-lisp-mode lisp-interaction-mode)
   nil
   ("Eval"
    (("eb" eval-buffer "buffer")
     ("ed" eval-defun "defun")
     ("ee" eval-last-sexp "expression")
     ("er" eval-region "region")
     ("eo" ielm "open repl"))
    "Compile"
    (("c" byte-compile-file "file"))
    "Check"
    (("C" checkdoc "checkdoc"))
    "Debug"
    (("E" toggle-debug-on-error "on error")
     ("q" toggle-debug-on-quit "on quit")
     ("d" debug-on-entry "on entry")
     ("D" cancel-debug-on-entry "cancel on entry"))
    "Test"
    (("t" ert "run"))))
  :config
  (defun panda-set-elisp-locals ()
    (setq panda-inner-defun-bounds '("(" . ")"))))

(use-package macrostep
  :mode-hydra
  ((emacs-lisp-mode lisp-interaction-mode)
   nil
   ("Debug"
    (("m" macrostep-expand "macrostep")))))

(use-package package-lint
  :mode-hydra
  ((emacs-lisp-mode lisp-interaction-mode)
   nil
   ("Check"
    (("p" package-lint-current-buffer "package-lint")))))

(use-package emr
  :mode-hydra
  ((emacs-lisp-mode lisp-interaction-mode)
   nil
   ("Refactor"
    (("l" emr-el-extract-to-let "extract to let")
     ("L" emr-el-inline-let-variable "inline let variable")))))

;;;; HTML / CSS
(use-package web-mode
  :mode (("\\.html?\\'" . web-mode))
  :gfhook '(lsp prettier-html-on-save-mode)
  :init
  (gsetq web-mode-enable-auto-closing t
         web-mode-enable-auto-indentation t
         web-mode-enable-auto-opening t
         web-mode-enable-auto-pairing t
         web-mode-enable-auto-quoting t
         web-mode-enable-css-colorization t
         web-mode-markup-indent-offset 2
         web-mode-style-padding 4
         web-mode-script-padding 4
         web-mode-block-padding 4)
  :config
  (defvar prettier-html-args '("--stdin" "--parser" "html")
    "Arguments for prettier with HTML.")
  (reformatter-define prettier-html
    :program "prettier"
    :args prettier-html-args))

(use-package css-mode
  :defer t
  :gfhook '(lsp prettier-css-on-save-mode)
  :config
  (defvar prettier-css-args '("--stdin" "--parser" "css" "--tab-width" "4")
    "Arguments for prettier with CSS.")
  (reformatter-define prettier-css
    :program "prettier"
    :args prettier-css-args))

(use-package emmet-mode
  :ghook '(web-mode-hook css-mode-hook))

;;;; JavaScript / TypeScript
(use-package js
  :defer t
  :gfhook '(lsp prettier-ts-on-save-mode))

(use-package rjsx-mode :defer t)

(use-package typescript-mode
  :defer t
  :gfhook '(lsp prettier-ts-on-save-mode))

(defvar prettier-ts-args '("--stdin" "--parser" "typescript" "--tab-width" "4")
  "Arguments for prettier with TypeScript.")

(reformatter-define prettier-ts
  :program "prettier"
  :args prettier-ts-args)

;;;; JSON
(use-package json-mode
  :defer t
  :gfhook '(prettier-json-on-save-mode)
  :config
  (defvar prettier-json-args '("--stdin" "--parser" "--json" "--tab-width" "4")
    "Arguments for prettier with JSON.")
  (reformatter-define prettier-json
    :program "prettier"
    :args prettier-json-args))

;;;; Kotlin
(use-package kotlin-mode
  :defer t
  :gfhook '(lsp panda-format-on-save-mode))

;;;; Latex
(use-package tex
  :straight auctex
  :defer t
  :gfhook ('LaTeX-mode-hook '(panda-format-on-save-mode))
  :config
  (gsetq TeX-auto-save t
         TeX-parse-self t))

;;;; Org
(use-package org
  :straight nil
  :gfhook 'panda-format-on-save-mode
  :general
  (panda-space
    "a" 'org-agenda
    "A" 'org-capture)
  :config
  (gsetq org-directory "~/org")
  (gsetq org-agenda-custom-commands
         '(("n" "Agenda and unscheduled TODOs"
            ((agenda "")
             (alltodo "" ((org-agenda-overriding-header "Unscheduled TODOs:")
                          (org-agenda-skip-function
                           '(org-agenda-skip-entry-if 'timestamp)))))))
         org-agenda-files (list (expand-file-name "agenda" org-directory))
         org-capture-templates '(("d" "Deadline TODO" entry (file "agenda/refile.org")
                                  "* TODO %?\n  DEADLINE: %t")
                                 ("s" "Scheduled TODO" entry (file "agenda/refile.org")
                                  "* TODO %?\n  SCHEDULED: %t")
                                 ("t" "TODO" entry (file "agenda/refile.org")
                                  "* TODO %?"))
         org-catch-invisible-edits 'error
         org-src-fontify-natively t
         org-src-tab-acts-natively t))

(use-package toc-org
  :ghook 'org-mode-hook)

(use-package org-bullets
  :ghook 'org-mode-hook)

(use-package helm-org-rifle :defer t)

(use-package evil-org
  :after org ; :after takes precedence over :demand
  :demand t ; required for evil-org-agenda to work properly
  :ghook 'org-mode-hook
  :config
  (evil-org-set-key-theme '(additional calendar insert navigation))
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

;;;; Python
(use-package python
  :defer t
  :gfhook '(black-on-save-mode lsp panda-set-python-locals)
  :mode-hydra
  (python-mode
   ("Eval"
    (("eb" python-shell-send-buffer "buffer")
     ("ed" python-shell-send-defun "defun")
     ("ef" python-shell-send-file "file")
     ("er" python-shell-send-region "region")
     ("eo" run-python "open repl"))))
  :config
  (gsetq python-indent-offset 4)
  (defun panda-set-python-locals ()
    (setq panda-inner-defun-bounds '(":" . ""))
    (gsetq-local yas-indent-line 'fixed)
    (gsetq-local yas-also-auto-indent-first-line nil))
  (progn
    (defvar black-args '("-" "--quiet" "--line-length" "80")
      "Arguments for black.")
    (reformatter-define black
      :program "black"
      :args black-args)))

;;;; R
(use-package ess
  :defer t
  :gfhook ('ess-r-mode-hook '(panda-format-on-save-mode lsp))
  :mode-hydra
  (ess-r-mode
   nil
   ("Eval"
    (("eb" ess-eval-buffer "buffer")
     ("ed" ess-eval-function "function")
     ("ef" ess-load-file "file")
     ("el" ess-eval-line "line")
     ("ep" ess-eval-paragraph "paragraph")
     ("er" ess-eval-region "region")
     ("eo" R "open repl"))))
  :config
  (gsetq ess-ask-for-ess-directory nil
         ess-use-flymake nil)
  (progn
    (lsp-register-client
     (make-lsp-client :new-connection (lsp-stdio-connection
                                       '("R" "--slave" "-e" "languageserver::run()"))
                      :major-modes '(ess-r-mode)
                      :server-id 'R))
    (add-to-list 'lsp-language-id-configuration '(ess-r-mode . "r"))))

;;;; Rust
(use-package rust-mode
  :defer t
  :gfhook '(lsp rustfmt-on-save-mode)
  :config
  (defvar rustfmt-args nil
    "Arguments for rustfmt.")
  (reformatter-define rustfmt
    :program "rustfmt"
    :args rustfmt-args))

(use-package cargo
  :ghook ('rust-mode-hook 'cargo-minor-mode))

;;;; Other
(use-package cmake-mode :defer t)
(use-package fish-mode :defer t)
(use-package gitattributes-mode :defer t)
(use-package gitconfig-mode :defer t)
(use-package gitignore-mode :defer t)
(use-package go-mode :defer t)
(use-package markdown-mode :defer t)
(use-package vimrc-mode :defer t)
(use-package yaml-mode :defer t)

;;; End Init
(provide 'init)

;; Local Variables:
;; eval: (when (fboundp 'outshine-mode) (outshine-mode 1))
;; End:
