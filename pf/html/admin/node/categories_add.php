<?php
/**
 * @licence http://opensource.org/licenses/gpl-2.0.php GPL
 */

  $current_top = 'node';
  $current_pfcmd = 'nodecategory';
  $current_sub = 'categories_add';

  include('../common.php');
?>

<html>
<head>
  <title>PF::NodeCategories::Add</title>
  <link rel="shortcut icon" href="/favicon.ico"> 
  <link rel="stylesheet" href="../style.css" type="text/css">
</head>

<body class="popup">

<?
  $edit_item = set_default($_REQUEST['item'], '');

  if($_POST){
    foreach($_POST as $key => $val){
      $parts[] = "$key=\"$val\""; 
    }
    $edit_cmd = "$current_pfcmd add ";
    $edit_cmd.=implode(", ", $parts);

    # I REALLLLYY mean false (avoids 0, empty strings and empty arrays to pass here)
    if (PFCMD($edit_cmd) === false) {
      # an error was shown by PFCMD now die to avoid closing the popup
      exit();
    }
    # no errors from pfcmd, go on
    $edited=true; 

    # refresh the nodecategory cache
    invalidate_nodecategory_cache();
    nodecategory_caching();

    print "<script type='text/javascript'>opener.location.reload();window.close();</script>";
  }

  $edit_info = new table("$current_pfcmd view $edit_item");

  print "<form name='edit' method='post' action='/$current_top/$current_sub.php'>";
  print "<div id='add'><table>";
  print "<tr><td><img src='../images/category.png'></td><td valign='middle' colspan=2><b>Adding new category: </b></td></tr>";
  foreach($edit_info->rows[0] as $key => $val){

    # don't show category id
    if($key=='category_id'){
      continue;
    }

    $pretty_key = pretty_header("$current_pfcmd-view", $key);
    print "<tr><td></td><td>$pretty_key:</td><td><input type='text' name='$key' value='$val'>";

    print "</td></tr>";
  }
  print "<tr><td colspan=3 align=right><input type='submit' value='Add category'></td></tr>";
  print "</table></div>";
  print "</form>";
?>

</html>
