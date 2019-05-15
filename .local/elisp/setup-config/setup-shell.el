;;; Shell
   (use-package sane-term
     :commands sane-term
     :init
     ;; shell to use for sane-term
     (setq sane-term-shell-command "/usr/local/bin/zsh")
     ;; sane-term will create first term if none exist
     (setq sane-term-initial-create t)
     ;; `C-d' or `exit' will kill the term buffer.
     (setq sane-term-kill-on-exit t)
     ;; After killing a term buffer, not cycle to another.
     (setq sane-term-next-on-kill nil))
   (use-package shell-pop
     :commands shell-pop
     :init
     (setq shell-pop-term-shell "/usr/local/bin/zsh")
     (setq shell-pop-shell-type '("eshell" "*eshell*" (lambda nil (eshell))))
     :config
       (defun ansi-term-handle-close ()
        "Close current term buffer when `exit' from term buffer."
        (when (ignore-errors (get-buffer-process (current-buffer)))
          (set-process-sentinel (get-buffer-process (current-buffer))
                                (lambda (proc change)
                                  (when (string-match "\\(finished\\|exited\\)" change)
                                    (kill-buffer (when (buffer-live-p (process-buffer proc)))
                                    (delete-window))))))
      (add-hook 'shell-pop-out-hook 'kill-this-buffer)
      (add-hook 'term-mode-hook (lambda () (linum-mode -1) (ansi-term-handle-close)))))
    ;; basic settings
    ;; (evil-set-initial-state 'term-mode 'emacs)
    (setq explicit-shell-file-name "/usr/local/bin/zsh")
    ;; don't add newline in long lines
    (setq-default term-suppress-hard-newline t)
    ;; kill process buffers without query
    (setq kill-buffer-query-functions (delq 'process-kill-buffer-query-function kill-buffer-query-functions))
    ;; (global-set-key (kbd "C-x k") 'kill-this-buffer)
    ;; kill ansi-buffer on exit
    (defadvice term-sentinel (around my-advice-term-sentinel (proc msg))
      (if (memq (process-status proc) '(signal exit))
          (let ((buffer (process-buffer proc)))
             ad-do-it
             (kill-buffer buffer))
            ad-do-it))
          (ad-activate 'term-sentinel)

   ;; clickable links & no highlight of line
   (defun my-term-hook ()
     (goto-address-mode) (global-hl-line-mode 0))
   (add-hook 'term-mode-hook 'my-term-hook)

   ;; paste and navigation
   (defun term-send-tab ()
   "Send tab in term mode."
     (interactive)
     (term-send-raw-string "\t"))

   ;; Emacs doesn’t handle less well, so use cat instead for the shell pager
   (setenv "PAGER" "cat")

   ;; hack to fix pasting issue, the paste micro-state won't work in term
   (general-define-key :states '(normal) :keymaps 'term-raw-map
          "p" 'term-paste
          "C-k" 'term-send-up
          "C-j" 'term-send-down)

   (general-define-key :states '(insert) :keymaps 'term-raw-map
          "C-c C-d" 'term-send-eof
          "C-c C-z" 'term-stop-subjob
          "<tab>"   'term-send-tab
          "s-v"     'term-paste
          "C-k"     'term-send-up
          "C-j"     'term-send-down)
 (setq compilation-finish-functions
       (lambda (buf str)
         (if (null (string-match ".*exited abnormally.*" str))
             ;;no errors, make the compilation window go away in a few seconds
             (progn
               (run-at-time "0.4 sec" nil
                            (lambda ()
                              (select-window (get-buffer-window (get-buffer-create "*compilation*")))
                              (switch-to-buffer nil)
                              (delete-window)))
               (message "No Compilation Errors!")))))
   ;; Remove completion buffer when done
   (add-hook 'minibuffer-exit-hook
   '(lambda ()
            (let ((buffer "*Completions*"))
              (and (get-buffer buffer)
               (kill-buffer buffer)))))
   (use-package virtualenvwrapper
    :after (:any eshell sane-term ansi-term)
    :config
    (venv-initialize-interactive-shells) ;; if you want interactive shell support
    (venv-initialize-eshell) ;; if you want eshell support
    (setq venv-location "~/bin/virtualenvs")
    (setq venv-project-home "~/Dropbox/Work/projects/")
    (add-hook 'venv-postactivate-hook (lambda () (workon-venv))))

   (defcustom venv-project-home
     (expand-file-name (or (getenv "PROJECT_HOME") "~/Dropbox/Work/projects/"))
       "The location(s) of your virtualenv projects."
       :group 'virtualenvwrapper)

   (defun workon-venv ()
    "change directory to project in eshell"
     (eshell/cd (concat venv-project-home venv-current-name)))
(use-package tramp-term
  :commands tramp-term
)
   (use-package eshell
     :commands eshell
     :init
     (setq eshell-directory-name (concat cpm-local-dir "eshell/")
           eshell-history-file-name (concat cpm-local-dir "eshell/history")
           eshell-aliases-file (concat cpm-local-dir "eshell/alias")
           eshell-last-dir-ring-file-name (concat cpm-local-dir "eshell/lastdir")
           eshell-highlight-prompt nil
           eshell-buffer-shorthand t
           eshell-cmpl-ignore-case t
           eshell-cmpl-cycle-completions t
           eshell-destroy-buffer-when-process-dies t
           eshell-history-size 10000
           ;; auto truncate after 20k lines
           eshell-buffer-maximum-lines 20000
           eshell-hist-ignoredups t
           eshell-error-if-no-glob t
           eshell-glob-case-insensitive t
           eshell-scroll-to-bottom-on-input 'all
           eshell-scroll-to-bottom-on-output 'all
           eshell-list-files-after-cd t
           eshell-banner-message ""
           ;; eshell-banner-message (message "Emacs initialized in %.2fs \n\n" (float-time (time-subtract (current-time) my-start-time)))
           ;; eshell-banner-message "What would you like to do?\n\n"
         )
         ;; Visual commands
     (setq eshell-visual-commands '("ranger" "vi" "screen" "top" "less" "more" "lynx"
                                        "ncftp" "pine" "tin" "trn" "elm" "vim"
                                        "nmtui" "alsamixer" "htop" "el" "elinks"
                                        ))
     (setq eshell-visual-subcommands '(("git" "log" "diff" "show"))))



   (defun cpm/setup-eshell ()
    (interactive)
     ;; turn off semantic-mode in eshell buffers
     (semantic-mode -1)
     ;; turn off hl-line-mode
     (hl-line-mode -1))
     ;; helm support
     (add-hook 'eshell-mode-hook
          (lambda ()
            (eshell-cmpl-initialize)
            (define-key eshell-mode-map [remap eshell-pcomplete] 'helm-esh-pcomplete)
            (define-key eshell-mode-map (kbd "M-l") 'helm-eshell-history)
            (cpm/setup-eshell)))

         (when (not (functionp 'eshell/rgrep))
           (defun eshell/rgrep (&rest args)
             "Use Emacs grep facility instead of calling external grep."
             (eshell-grep "rgrep" args t)))
(defun my/truncate-eshell-buffers ()
  "Truncates all eshell buffers"
  (interactive)
  (save-current-buffer
    (dolist (buffer (buffer-list t))
      (set-buffer buffer)
      (when (eq major-mode 'eshell-mode)
        (eshell-truncate-buffer)))))

;; After being idle for 5 seconds, truncate all the eshell-buffers if
;; needed. If this needs to be canceled, you can run `(cancel-timer
;; my/eshell-truncate-timer)'
(setq my/eshell-truncate-timer
      (run-with-idle-timer 5 t #'my/truncate-eshell-buffers))
(add-hook 'eshell-mode-hook
(lambda ()
(general-define-key :states  '(normal insert emacs) :keymaps 'eshell-mode-map
    "<down>" 'eshell-next-input
    "<up>"   'eshell-previous-input
    "C-k"    'eshell-next-input
    "C-j"    'eshell-previous-input)
    ))
  (require 'dash)
  (require 's)

  (defmacro with-face (STR &rest PROPS)
    "Return STR propertized with PROPS."
    `(propertize ,STR 'face (list ,@PROPS)))

  (defmacro esh-section (NAME ICON FORM &rest PROPS)
    "Build eshell section NAME with ICON prepended to evaled FORM with PROPS."
    `(setq ,NAME
           (lambda () (when ,FORM
                   (-> ,ICON
                      (concat esh-section-delim ,FORM)
                      (with-face ,@PROPS))))))

  (defun esh-acc (acc x)
    "Accumulator for evaluating and concatenating esh-sections."
    (--if-let (funcall x)
        (if (s-blank? acc)
            it
          (concat acc esh-sep it))
      acc))

  (defun esh-prompt-func ()
    "Build `eshell-prompt-function'"
    (concat esh-header
            (-reduce-from 'esh-acc "" eshell-funcs)
            "\n"
            eshell-prompt-string))

  (esh-section esh-dir
               "\xf07c"  ;  (faicon folder)
               (abbreviate-file-name (eshell/pwd))
               '(:foreground "#268bd2" :underline t))

  (esh-section esh-git
               "\xe907"  ;  (git icon)
               (with-eval-after-load 'magit
               (magit-get-current-branch))
               '(:foreground "#b58900"))

  (esh-section esh-python
               "\xe928"  ;  (python icon)
               (with-eval-after-load "virtualenvwrapper"
               venv-current-name))

  (esh-section esh-clock
               "\xf017"  ;  (clock icon)
               (format-time-string "%H:%M" (current-time))
               '(:foreground "forest green"))

  ;; Below I implement a "prompt number" section
  (setq esh-prompt-num 0)
  (add-hook 'eshell-exit-hook (lambda () (setq esh-prompt-num 0)))
  (advice-add 'eshell-send-input :before
              (lambda (&rest args) (setq esh-prompt-num (incf esh-prompt-num))))

  (esh-section esh-num
               "\xf0c9"  ;  (list icon)
               (number-to-string esh-prompt-num)
               '(:foreground "brown"))

  ;; Separator between esh-sections
  (setq esh-sep " | ")  ; or "  "

  ;; Separator between an esh-section icon and form
  (setq esh-section-delim " ")

  ;; Eshell prompt header
  (setq esh-header "\n┌─")  ; or "\n "

  ;; Eshell prompt regexp and string. Unless you are varying the prompt by eg.
  ;; your login, these can be the same.
  (setq eshell-prompt-regexp "^└─>> ") ;; note the '^' to get regex working right
  (setq eshell-prompt-string "└─>> ")

  ;; Choose which eshell-funcs to enable
  (setq eshell-funcs (list esh-dir esh-git esh-python esh-clock esh-num))

  ;; Enable the new eshell prompt
  (setq eshell-prompt-function 'esh-prompt-func)
   (use-package shell-switcher
     :general
     ("C-'"  'shell-switcher-switch-buffer-other-window)
     :config
     (add-hook 'eshell-mode-hook 'shell-switcher-manually-register-shell)
     (setq shell-switcher-mode t))
   (defun eshell-clear-buffer ()
   "Clear terminal"
   (interactive)
   (let ((inhibit-read-only t))
     (erase-buffer)
     (eshell-send-input)))
 (add-hook 'eshell-mode-hook
       '(lambda()
           (local-set-key (kbd "C-l") 'eshell-clear-buffer)))
 (defun eshell/magit ()
 "Function to open magit-status for the current directory"
   (interactive)
   (magit-status default-directory)
   nil)
(use-package eshell-fringe-status
  :defer t
  :config
  (add-hook 'eshell-mode-hook 'eshell-fringe-status-mode))
(use-package esh-autosuggest
  :hook (eshell-mode . esh-autosuggest-mode))

(provide 'setup-shell)