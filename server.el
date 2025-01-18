(require 'web-server)
(defvar eos-port 9000)			;Temporary

(defvar eos-handlers
  '(((:GET . "/index") . eos-index)
    ((:GET . "\.org") . eos-org-file)	; This needs to change & I need to handle 404-ing from inside eos-org-file
    ((:GET . ".*") . eos-404)
    ))

(defun eos-index (request)
  "Generate index.html"
  (with-slots (process headers) request
    (ws-response-header process 200 '("Content-type" . "text/html"))
    (process-send-string (process request)
			 (concat
			  "<!DOCTYPE html>"
			  "<script src=\"https://unpkg.com/htmx.org@2.0.4\" integrity=\"sha384-HGfztofotfshcF7+8n44JQL2oJmowVChPTg48S+jvZoztPfvwD79OC/LTtG6dMp+\" crossorigin=\"anonymous\"></script>"
			  (eos-render-org-file "index.org")
			  "</html>"))))

(defun eos-org-file (request)
  "Generate and serve an org-mode file"
  (with-slots (process headers) request
    (let ((file (eos-get-file headers)))
      (if (file-exists-p file)
	  (progn
	    (ws-response-header process 200 '("Content-type" . "text/html"))
	    (process-send-string (process request) (eos-render-org-file file)))
	(eos-404 request)))))

(defun eos-get-file (headers)
  "Get the name of the requested file from the header provided"
  (cdr (assoc :GET headers)))		; Temporary

(defun eos-render-org-file (file)
  "Render an org file into a string of HTML"
      (with-temp-buffer
        (insert-file-contents file)
	(org-export-to-buffer 'html "*auto-org-export*" '() '() '() t)
	(goto-char (point-max))
	(insert "<div id=\"htmx-target\"></div>")
	(buffer-string)))

(defun eos-404 (request)
  "Serve a 404 page"
  (with-slots (process headers) request
    (ws-response-header process 404 '("Content-type" . "text/plain"))
    (process-send-string (process request) "404. Request a file on the machine")))

(defun eos-run ()
  "Run the elisp org server (name not final)"
  (ws-start eos-handlers eos-port))

(eos-run)
