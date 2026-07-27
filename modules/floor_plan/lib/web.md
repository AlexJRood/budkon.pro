<script>
  window.addEventListener(
    'wheel',
    function (event) {
      if (event.ctrlKey || event.metaKey || event.altKey || event.shiftKey) {
        event.preventDefault();
      }
    },
    { passive: false }
  );
</script>