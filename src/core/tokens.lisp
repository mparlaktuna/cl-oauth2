(in-package :cl-oauth2)

;;;  OAuth 2.0 Authentication is done in three steps:
;;;
;;;    1. The user authorizes the consumer.
;;;    2. The consumer obtains an authorization code.
;;;    3. The consumer exchanges the authorization code for an access token.
;;;


;;; token base class
(defclass token ()
  ((name           :type string
                   :accessor token-name
                   :initarg :name
                   :initform "default"
                   :documentation "For verification that correct token is in use.")
   (store-path     :type pathname
                   :accessor token-store-path
                   :initarg :store-path
                   :initform #P"/tmp/token.store"
                   :documentation "Path to store this token at.")
   (access-key     :type string
                   :accessor token-access-key
                   :initarg :access-key
                   :initform nil)
   (refresh-key    :type string
                   :accessor token-refresh-key
                   :initarg :refresh-key
                   :initform nil)
   (code           :type string
                   :accessor token-code
                   :initarg :code
                   :initform nil
                   :documentation "Grant code used to receive token.")
   (state          :type string
                   :accessor token-state
                   :initarg :state
                   :initform nil
                   :documentation "A random string generated by the application, for verification")
   (timestamp      :type (or integer null)
                   :accessor token-access-key-creation-time
                   :initarg :timestamp
                   :initform (get-universal-time)
                   :documentation "Universal time when this token was created.")
   (redirect-uri   :type string
                   :accessor token-redirect-uri
                   :initarg :redirect-uri
                   :initform nil
                   :documentation "Redirect URI of consumer.")
   (redirect-port  :type int
                   :accessor token-redirect-port
                   :initarg :redirect-port
                   :initform 12346
                   :documentation "OAuth needs a callback server. We'll attempt to start a server on localhost at this port.
                                   You're responsible to do the necessary port forwarding.")
   (user-data      :type list
                   :accessor token-user-data
                   :initarg :user-data
                   :initform nil
                   :documentation "Application-specific data associated  with this token; an alist.")
   (user-id        :type (or string null)
                   :accessor token-user-id
                   :initarg :user-id
                   :initform nil
                   :documentation "Returned with access token.")
   (client-id      :type (or string null)
                   :accessor token-client-id
                   :initarg :client-id
                   :initform nil)
   (client-secret  :type (or string null)
                   :accessor token-client-secret
                   :initarg :client-secret
                   :initform nil)
   (expires        :type (or integer null)
                   :accessor token-access-key-expires
                   :initarg :access-key-expires
                   :initform 0
                   :documentation "Time in seconds this token will be valid.")
   (scope          :type string
                   :accessor token-scope
                   :initarg :scope
                   :initform nil
                   :documentation "Scope this token is valid for.")
   (code-uri       :type (or puri:uri string null)
                   :accessor token-code-uri
                   :initarg :code-uri
                   :initform nil
                   :documentation "URI the token grant code has been obtained from.")
   (token-uri      :type (or puri:uri string null)
                   :accessor token-token-uri
                   :initarg :token-uri
                   :initform nil
                   :documentation "URI this access token has been obtained from.
                     Needed for refresh.")))

(defun make-token (&rest args)
  (apply #'make-instance 'token args))

(defun token-expired-p (token)
  (and (token-access-key-creation-time token)
       (not (= 0 (token-access-key-expires token)))
       (> (get-universal-time) (+ (token-access-key-creation-time token) (token-access-key-expires token)))))

(defmethod print-object ((obj token) stream)
  "Faking STRUCT-like output. It would probably be better to use
  the pretty printer; the code for sb-kernel::%default-structure-pretty-print
  will be a useful template."
  (print-unreadable-object (obj stream :type t :identity (not *print-pretty*))
    (loop for slotname in (mapcar #'c2mop:slot-definition-name
                                  (c2mop:class-slots (class-of obj)))
          do (progn
               (terpri stream)
               (write "  " :stream stream :escape nil)
               (prin1 (intern (symbol-name slotname) :keyword) stream)
               (write " " :stream stream :escape nil)
               (prin1 (if (slot-boundp obj slotname)
                        (slot-value obj slotname)
                        "(unbound)")
                      stream)))))
