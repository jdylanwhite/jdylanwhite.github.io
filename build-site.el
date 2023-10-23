;; Initialize package sources
(require 'package)

;; Set the package installation directory so that packages aren't stored in the
;; ~/.emacs.d/elpa path.
(setq package-user-dir (expand-file-name "./.packages"))

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/"))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install use-package
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)

;; Require built-in dependencies
(require 'vc-git)
(require 'ox-publish)
(require 'subr-x)
(require 'cl-lib)

;; Install other dependencies
(use-package esxml
  :pin "melpa-stable"
  :ensure t)

(use-package htmlize
  :ensure t)

(use-package webfeeder
  :ensure t)

(use-package ess
  :ensure t)

(setq user-full-name "J. Dylan White")
(setq user-mail-address "jdylanwhite5@gmail.com")

(defvar dw/site-url (if (string-equal (getenv "CI") "true")
                        "https://jdylanwhite.github.io"
                        "http://localhost:8080")
  "The URL for the site being generated.")

(defun dw/site-header ()
  (list `(header (@ (class "site-header"))
                 (div (@ (class "container"))
                      (div (@ (class "site-title"))
                           (a (@ (class "site-name") (href "/")) "J. Dylan White") " "))
                 (div (@ (class "site-masthead"))
                      (div (@ (class "container"))
                           (nav (@ (class "nav"))
                                (a (@ (class "nav-link") (href "/")) "Home") " "
                                (a (@ (class "nav-link") (href "/projects/")) "Projects") " "
                                (a (@ (class "nav-link") (href "/dotfiles/")) "Dotfiles") " "))))))

(defun dw/site-footer ()
  (list `(footer (@ (class "site-footer"))
                 (div (@ (class "container"))
                      (div (@ (class "row"))
                           (div (@ (class "column"))
                                (p (a (@ (href "https://github.com/jdylanwhite")) "GitHub")
                                   " · "
                                   (a (@ (href "https://www.linkedin.com/in/jdylanwhite5")) "LinkedIn")
                                   " · "
                                   (a (@ (href "mailto:jdylanwhite5@gmail.com")) "Email")))
                          (div (@ (class "column align-right"))
                                (p (a (@ (href "https://github.com/jdylanwhite/jdylanwhite.github.io")) "Site Source"))))))))

(defun dw/get-commit-hash ()
  "Get the short hash of the latest commit in the current repository."
  (string-trim-right
   (with-output-to-string
     (with-current-buffer standard-output
       (vc-git-command t nil nil "rev-parse" "--short" "HEAD")))))

(cl-defun dw/generate-page (title
                            content
                            info
                            &key
                            (publish-date)
                            (head-extra)
                            (pre-content)
                            (exclude-header)
                            (exclude-footer))
  (message title)
  (concat
   "<!-- Generated from " (dw/get-commit-hash)  " on " (format-time-string "%Y-%m-%d @ %H:%M") " with " org-export-creator-string " -->\n"
   "<!DOCTYPE html>"
   (sxml-to-xml
    `(html (@ (lang "en"))
      (head
       (meta (@ (charset "utf-8")))
       (meta (@ (author "J. Dylan White")))
       (meta (@ (name "viewport")
                (content "width=device-width, initial-scale=1, shrink-to-fit=no")))
       (link (@ (rel "stylesheet") (href ,(concat dw/site-url "/css/code.css"))))
       (link (@ (rel "stylesheet") (href ,(concat dw/site-url "/css/site.css"))))
       ,(when head-extra head-extra)
       (title ,(concat title " - J. Dylan White")))
      (body ,@(unless exclude-header
                (dw/site-header))
            (div (@ (class "container"))
                 (div (@ (class "site-post"))
                      (h1 (@ (class "site-post-title"))
                          ,title)
                      ,(when publish-date
                         `(p (@ (class "site-post-meta")) ,publish-date))
                      ,(when pre-content pre-content)
                      (div (@ (id "content"))
                           ,content)))
            ,@(unless exclude-footer
                (dw/site-footer)))))))

(defun dw/org-html-template (contents info)
  (dw/generate-page (org-export-data (plist-get info :title) info)
                    contents
                    info
                    :publish-date (org-export-data (org-export-get-date info "%B %e, %Y") info)))

(defun dw/org-html-src-block (src-block _contents info)
  (let* ((lang (org-element-property :language src-block))
	       (code (org-html-format-code src-block info)))
    (format "<pre>%s</pre>" (string-trim code))))

(defun dw/org-html-table (table contents info)
  "Transcode a TABLE element from Org to HTML.
CONTENTS is the contents of the table.  INFO is a plist holding
contextual information."
  (if (eq (org-element-property :type table) 'table.el)
      ;; "table.el" table.  Convert it using appropriate tools.
      (org-html-table--table.el-table table info)
    ;; Standard table.
    (let* ((caption (org-export-get-caption table))
	   (number (org-export-get-ordinal
		    table info nil #'org-html--has-caption-p))
           (format "<div class=table-wrapper><table%s>\n%s\n%s\n%s</table></div>"
                   (if (not caption) ""
                     (format (if (plist-get info :html-table-caption-above)
                                 "<caption class=\"t-above\">%s</caption>"
			         "<caption class=\"t-bottom\">%s</caption>")
                             (concat
                              "<span class=\"table-number\">"
                              (format (org-html--translate "Table %d:" info) number)
                              "</span> " (org-export-data caption info))))
                   (funcall table-column-specs table info)
                   contents))))



(defun dw/make-heading-anchor-name (headline-text)
  (thread-last headline-text
    (downcase)
    (replace-regexp-in-string " " "-")
    (replace-regexp-in-string "[^[:alnum:]_-]" "")))

(defun dw/org-html-headline (headline contents info)
  (let* ((text (org-export-data (org-element-property :title headline) info))
         (level (org-export-get-relative-level headline info))
         (level (min 7 (when level (1+ level))))
         (anchor-name (dw/make-heading-anchor-name text))
         (attributes (org-element-property :ATTR_HTML headline))
         (container (org-element-property :HTML_CONTAINER headline))
         (container-class (and container (org-element-property :HTML_CONTAINER_CLASS headline))))
    (when attributes
      (setq attributes
            (format " %s" (org-html--make-attribute-string
                           (org-export-read-attribute 'attr_html `(nil
                                                                   (attr_html ,(split-string attributes))))))))
    (concat
     (when (and container (not (string= "" container)))
       (format "<%s%s>" container (if container-class (format " class=\"%s\"" container-class) "")))
     (if (not (org-export-low-level-p headline info))
         (format "<h%d%s><a id=\"%s\" class=\"anchor\" href=\"#%s\">¶</a>%s</h%d>%s"
                 level
                 (or attributes "")
                 anchor-name
                 anchor-name
                 text
                 level
                 (or contents ""))
       (concat
        (when (org-export-first-sibling-p headline info) "<ul>")
        (format "<li>%s%s</li>" text (or contents ""))
        (when (org-export-last-sibling-p headline info) "</ul>")))
     (when (and container (not (string= "" container)))
       (format "</%s>" (cl-subseq container 0 (cl-search " " container)))))))

(org-export-define-derived-backend 'site-html 'html
  :translate-alist
  '((template . dw/org-html-template)
    (headline . dw/org-html-headline)
    (src-block . dw/org-html-src-block)
    (table . dw/org-html-table)))

(defun org-html-publish-to-html (plist filename pub-dir)
  "Publish an org file to HTML.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'site-html filename
		      (concat (when (> (length org-html-extension) 0) ".")
			      (or (plist-get plist :html-extension)
				  org-html-extension
				  "html"))
		      plist pub-dir))

(setq org-publish-use-timestamps-flag t
      org-publish-timestamp-directory "./.org-cache/"
      org-export-with-section-numbers nil
      org-export-use-babel nil
      org-export-with-smart-quotes t
      org-export-with-sub-superscripts nil
      org-export-with-tags 'not-in-toc
      org-html-htmlize-output-type 'css
      org-html-prefer-user-labels t
      org-html-link-home dw/site-url
      org-html-link-use-abs-url t
      org-html-link-org-files-as-html t
      org-html-html5-fancy t
      org-html-self-link-headlines t
      org-export-with-toc nil
      make-backup-files nil)

(setq org-publish-project-alist
      (list '("main"
              :recursive t
              :base-directory "./content"
              :base-extension "org"
              :publishing-directory "./public"
              :publishing-function org-html-publish-to-html
              :with-title nil
              :with-timestamps nil)
            '("images"
              :recursive t
              :base-directory "./content"
              :base-extension "png"
              :publishing-directory "./public"
              :publishing-function org-publish-attachment)
            '("assets"
              :base-directory "./assets"
              :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|woff2\\|ttf"
              :publishing-directory "./public"
              :recursive t
              :publishing-function org-publish-attachment)))

(defun dw/publish ()
  "Publish the entire site."
  (interactive)
  (org-publish-all (string-equal (or (getenv "FORCE")
                                     (getenv "CI"))
                                 "true")))

(provide 'publish)
;;; publish.el ends here
