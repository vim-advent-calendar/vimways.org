{{ define "main" }}

<div class="home">
 
  
    <div class="row pack">

        {{ $paginator := .Paginate (where .Pages "Section" "posts") }}
        {{ range $paginator.Pages }}   
            <div class="col-md-4 card">
             <a href="{{ .Permalink }}" class="index-anchor">    
                <div class="panel panel-default">
                  
                  {{ if .Params.img }}
                  <img width="100%" src="{{ .Site.BaseURL }}images/{{ .Params.img }}" alt="{{ .Title }}">
                  {{ else }}
                  <img width="100%" src="{{ .Site.BaseURL }}images/{{ .Site.Params.defaultImage }}" alt="{{ .Site.Title }}">
                  {{ end }}
                  
                  <div class="panel-body">
                    <h3 class="panel-title pull-left">{{ .Title | truncate 25 }}</h3><span class="post-meta pull-right"><small>{{ .Date.Format "January 2, 2006" }}</small></span>
                  </div>
                  
                  <div class="panel-body"><small>
                    {{ .Summary | plainify | truncate 180 }}</small>
                  </div>
                </div>
                </a>
            </div>
        
          {{ end }}

    </div> 
    
<div class="row">
    <div class="col-md-4">  </div>
    <div class="col-md-4">
        {{ if gt .Paginator.TotalPages 1 }}
        <ul class="pagination">
          {{ if .Paginator.HasPrev }}
            <li><a href="{{ .Paginator.Prev.URL }}">&laquo; Prev</a></li>
          {{ else }}
            <li><span>&laquo; Prev</span></li>
          {{ end }}

          {{ $scratch := newScratch }}
          {{ $scratch.Set "current" .Paginator.PageNumber }} 

          {{ range .Paginator.Pagers }}
            {{ if eq .PageNumber ($scratch.Get "current") }}
              <li class="active"><span><em>{{ .PageNumber }}</em></span></li>
            {{ else }}
            <li><a href="{{ .URL }}">{{ .PageNumber }}</a></li>
            {{ end }}
          {{ end }}

          {{ if .Paginator.HasNext }}
            <li><a href="{{ .Paginator.Next.URL }}">Next &raquo;</a></li>
          {{ else }}
            <li><span >Next &raquo;</span></li>
          {{ end }}
          </ul>
        {{ end }}

    </div>
    <div class="col-md-4">  </div>
</div>
</div>

{{ end }}
