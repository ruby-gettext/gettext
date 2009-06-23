# Contains data related to the expression or sentence that 
# is to be translated.
#
# Note by Vladimir: we can start inheriting from Array -
# an array with two elements is used by gettext originally.
# A real class would be better way to accomodate all the
# data related to the translation target.
class TranslationTarget < Array
  attr_accessor :translator_comment
  # TODO: migrate original two-element array to this methods
  # attr_accessor :msgid, :occurences
end
