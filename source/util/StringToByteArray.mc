import Toybox.Lang;
using Toybox.StringUtil;
using Toybox.Math;
function string_to_byte_array(plain_text) {
  var options = {
    :fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
    :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
    :encoding => StringUtil.CHAR_ENCODING_UTF8,
  };

  //System.println(Lang.format("Converting '$1$' to ByteArray", [ plain_text ]));
  var result = StringUtil.convertEncodedString(plain_text, options);
  //System.println(Lang.format("           '$1$'..", [ result ]));

  return result;
}

function valueRound(value, format) {
  var rounded;
  rounded = Math.round(value * 100) / 100;
  return rounded.format(format);
}
