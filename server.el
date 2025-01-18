(require 'web-server)
(defvar eos-port 9000)
(defvar eos-home-dir "")
(setq org-html-link-org-files-as-html '())
(defvar eos-index-file "")

(defvar eos-handlers
  '(((:GET . "/index") . eos-index)
    ((:GET . "\.org") . eos-org-file)
    ((:GET . ".*") . eos-other-file)
    ))

(defun eos-index (request)
  "Generate index.html"
  (with-slots (process headers) request
    (ws-response-header process 200 '("Content-type" . "text/html"))
    (process-send-string (process request)
			 (concat
			  "<!DOCTYPE html>"
			  "<script src=\"https://unpkg.com/htmx.org@2.0.4\" integrity=\"sha384-HGfztofotfshcF7+8n44JQL2oJmowVChPTg48S+jvZoztPfvwD79OC/LTtG6dMp+\" crossorigin=\"anonymous\"></script>"
			  (eos-render-org-file eos-index-file)
			  "</html>"))))

(defun eos-404 (request)
  "Serve a 404 page"
  (with-slots (process headers) request
    (ws-response-header process 404 '("Content-type" . "text/plain"))
    (process-send-string (process request) "404. Request a file on the machine")))

(defun eos-other-file (request)
  "Deal with non-org files"
  (with-slots (process headers) request
    (let ((file (eos-get-file headers))
	  (coding-system-for-read 'no-conversion))
      (if (file-exists-p file)
	  (progn
	        (ws-response-header process 200 '("Content-type" . "application/octet-stream")) ; Don't care what it is
		(process-send-string (process request)
				     (with-temp-buffer
				       (insert-file-contents-literally file)
				       (buffer-string))))
	(eos-404 request)))))


(defun eos-org-file (request)
  "Generate and serve an org-mode file"
  (with-slots (process headers) request
    (let ((file (eos-get-file headers)))
      (message file)
      (if (file-exists-p file)
	  (progn
	    (ws-response-header process 200 '("Content-type" . "text/html"))
	    (process-send-string (process request) (eos-render-org-file file)))
	(eos-404 request)))))

(defun eos-get-file (headers)
  "Get the name of the requested file from the header provided"
  (let ((rawname (cdr (assoc :GET headers))))
    (replace-regexp-in-string "^/" "" rawname)))

(defun eos-render-org-file (file)
  "Render an org file into a string of HTML"
      (with-temp-buffer
        (insert-file-contents file)
	(org-export-to-buffer 'html "*auto-org-export*" '() '() '() t)
	(goto-char (point-max))
	(insert "<div id=\"htmx-target\"></div>")
	(goto-char (point-min))
	(eos-htmxify-org-buffer)
	(buffer-string)))

(defun eos-htmxify-org-buffer ()
  "Transform regular links to all .org files in the buffer to HTMX replacement ones"
  (if (eq '() (search-forward-regexp "href=\".*\.org\"" '() t))
      '()				; Recursive definition because why not
      (progn
	(search-backward "=" '() t)
	(backward-kill-word 1)
	(insert "hx-get")
	(search-forward "\"" '() t 2)
	(insert " hx-target=\"#htmx-target\" hx-swap=\"outerHTML\" hx-trigger=\"click\"")
	(eos-htmxify-org-buffer))))

(defun eos-run ()
  "Run the elisp org server (name not final)"
  (cd eos-home-dir)
  (ws-start eos-handlers eos-port))

