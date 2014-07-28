---
title: SSL Certificates with HAProxy

---


<table class="row">
  <tr>
    <td class="wrapper last">

      <table class="twelve columns">
        <tr>
          <td>
            <h2>{{ page.title }}</h2>
            <p class="lead" style="font-style:italic;">In the last edition, we explored using HAProxy for load balancing. This week, we'll take that another step forward and learn about using SSL certificates with HAProxy!</p>
          </td>
          <td class="expander"></td>
        </tr>
      </table>

    </td>
  </tr>
</table>

<table class="row callout">
  <tr>
    <td class="wrapper last">

      <table class="twelve columns">
        <tr>
          <td class="panel">

            <h3>Servers for Hackers eBook!</h3>
            <p> I'm super excited to let you all know that I'm writing the <a href="http://book.serversforhackers.com">Servers for Hackers <strong>eBook</strong></a>! This will cover a lot of the material seen on this newsletter as well as many <strong>new topics</strong> - all <strong>more in depth</strong> than is feasible in this newsletter.</p>
            <p>Readers for Servers for Hackers will <strong>get a discount</strong> - keep on the lookout for updates!</p>
          </td>
          <td class="expander"></td>
        </tr>
      </table>

    </td>
  </tr>
</table>

<table class="row">
  <tr>
    <td class="wrapper last">

      <table class="twelve columns">
        <tr>
          <td>
            <h3>HAProxy with SSL Termination</h3>
            <p>We'll first cover the most typical way SSL certificates are setup with Load Balancers - using SSL Termination. This will show how to create an SSL certificate, which HAProxy 1.5+ can use to handle SSL traffic.</p>
          </td>
          <td class="expander"></td>
        </tr>
      </table>

    </td>
  </tr>
</table>

<table class="row">
  <tr>
    <td class="wrapper last">

      <table class="three columns">
        <tr>
          <td>

            <table class="button">
              <tr>
                <td>
                  <a href="http://serversforhackers.com/editions/2014/07/29/haproxy-ssl-termation-pass-through#ssl_termination">Read It!</a>
                </td>
              </tr>
            </table>

          </td>
          <td class="expander"></td>
        </tr>
      </table>

    </td>
  </tr>
</table>

<table class="row callout">
  <tr>
    <td class="wrapper last">

      <table class="twelve columns">
        <tr>
          <td class="panel">

            <p>This edition of Servers for Hackers is sponsored by <a href="https://larajobs.com/?partner=19" title="Larajobs">Larajobs</a> - Jobs for web artisans. This site is a listing of jobs for <strong>all developers</strong>, made and supported by the Laravel community.</p>
          </td>
          <td class="expander"></td>
        </tr>
      </table>

    </td>
  </tr>
</table>

<table class="row">
  <tr>
    <td class="wrapper last">

      <table class="twelve columns">
        <tr>
          <td>
            <h3>HAProxy with SSL Pass-Through</h3>
            <p>After SSL-Termination, we'll explore SSL Pass-Through, where the individual  back end servers are responsible for handling the SSL traffic. This requires some extra configuration of HAProxy, along with some careful consideration of the pros and cons of the two methods.</p>
          </td>
          <td class="expander"></td>
        </tr>
      </table>

    </td>
  </tr>
</table>

<table class="row">
  <tr>
    <td class="wrapper last">

      <table class="three columns">
        <tr>
          <td>

            <table class="button">
              <tr>
                <td>
                  <a href="http://serversforhackers.com/editions/2014/07/29/haproxy-ssl-termation-pass-through#ssl_passthru">Read It!</a>
                </td>
              </tr>
            </table>

          </td>
          <td class="expander"></td>
        </tr>
      </table>

    </td>
  </tr>
</table>