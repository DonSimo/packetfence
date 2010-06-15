<?php
/**
 * @licence http://opensource.org/licenses/gpl-2.0.php GPL
 */

  $current_top = 'configuration';
  $current_sub = 'floatingnetworkdevice';

  include('../common.php');
?>

<html>
<head>
  <title>PF::Configuration::FloatingNetworkDevice::Add</title>
  <link rel="shortcut icon" href="/favicon.ico"> 
  <link rel="stylesheet" href="../style.css" type="text/css">
</head>

<body class="popup">

<?
  $edit_item = set_default($_REQUEST['item'], '');

  if($_POST){
    foreach($_POST as $key => $val){
      if ($key == 'floatingnetworkdevice') {
        $edit_item = $val;
      } else {
        if (is_array($val)) {
          $parts[] = "$key=\"" . join(",", $val) . "\"";
        } else {
          $parts[] = "$key=\"$val\""; 
        }
      }
    }
    $edit_cmd = "floatingnetworkdeviceconfig add $edit_item ";
    $edit_cmd.=implode(", ", $parts);

    # I REALLLLYY mean false (avoids 0, empty strings and empty arrays to pass here)
    if (PFCMD($edit_cmd) === false) {
      # an error was shown by PFCMD now die to avoid closing the popup
      exit();
    }
    # no errors from pfcmd, go on
    $edited=true; 
    print "<script type='text/javascript'>opener.focus(); opener.location.href = opener.location; self.close();</script>";

  }

  $edit_info = new table("floatingnetworkdeviceconfig get $edit_item");

  print "<form name='edit' method='post' action='/$current_top/" . $current_sub . "_add.php?item=$edit_item'>";
  print "<div id='add'><table>";
  print "<tr><td><img src='../images/node.png'></td><td valign='middle' colspan=2><b>Adding new floating network device:</b></td></tr>";
  foreach($edit_info->rows[0] as $key => $val){
    if($key == $edit_info->key){
      continue;
    }
    if($key == "floatingnetworkdevice") {
      $val = '';
    }

    $pretty_key = pretty_header("configuration-floatingnetworkdevice", $key);
    if ($key == 'trunkPort') {
      print "<tr><td></td><td>$pretty_key:</td><td>";
      printSelect( array('' => 'please choose',
                         'yes' => 'yes',
                         'no' => 'no',
                    ),
                   'hash', $val, "name='$key'");
    } else {
      print "<tr><td></td><td>$pretty_key:</td><td><input type='text' name='$key' value='$val'>";
    }

    print "</td></tr>";
  }
  print "<tr><td colspan=3 align=right><input type='submit' value='Add floating network device'></td></tr>";
  print "</table></div>";
  print "</form>";
?>

</html>
