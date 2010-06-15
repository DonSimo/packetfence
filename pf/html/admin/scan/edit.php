<?php
/**
 * @licence http://opensource.org/licenses/gpl-2.0.php GPL
 */

  $current_top = 'scan';
  $current_sub = 'edit';

  include('../common.php');
?>
<html>
<head>
  <title>PF::Scan::Edit</title>
  <link rel="shortcut icon" href="/favicon.ico"> 
  <link rel="stylesheet" href="../style.css" type="text/css">
</head>

<body class="popup">

<?
  $edit_item = '';
  if (isset($_REQUEST['item']) && is_numeric($_REQUEST['item']) && ($_REQUEST['item'] >= 0)) {
    $edit_item = $_REQUEST['item'];
  }

  if($_POST){
    $edit_cmd = "schedule edit $edit_item ";
    foreach($_POST as $key => $val){
      $parts[] = "$key=\"$val\""; 
    }
    $edit_cmd.=implode(", ", $parts);

    # I REALLLLYY mean false (avoids 0, empty strings and empty arrays to pass here)
    if (PFCMD($edit_cmd) === false) {
      # an error was shown by PFCMD now die to avoid closing the popup
      exit();
    }
    # no errors from pfcmd, go on
    $edited=true; 
    print "<script type='text/javascript'>opener.location.reload();window.close();</script>";
  }

  $edit_info = new table("schedule view $edit_item");

  print "<form method='post' action='/$current_top/edit.php?item=$edit_item'>";
  print "<div id='add'><table>";
  print "<tr><td><img src='../images/person.png'></td><td valign='middle' colspan=2><b>Editing Schedule</b></td></tr>";
  foreach($edit_info->rows[0] as $key => $val){
    if($key == 'id'){
      continue;
    }

    $pretty_key = pretty_header("$current_top-view", $key);
    print "<tr><td></td><td>$pretty_key:</td><td><input type='text' name='$key' value='$val'></td></tr>";
  }
  print "<tr><td colspan=3 align=right><input type='submit' value='Edit ".ucfirst($current_top)."'></td></tr>";
  print "</table></div>";
  print "</form>";

?>
</html>
